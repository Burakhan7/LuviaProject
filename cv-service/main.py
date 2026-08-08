# main.py — Luvia CV servisi (gerçek FashionCLIP + renk analizi)
import colorsys
from io import BytesIO

import requests
import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from PIL import Image
from transformers import CLIPModel, CLIPProcessor
import uuid
import firebase_admin
from transformers import SegformerImageProcessor, AutoModelForSemanticSegmentation
import torch.nn.functional as F
import numpy as np
from concurrent.futures import ThreadPoolExecutor
import time
from scipy import ndimage
from firebase_admin import credentials, storage
from rembg import remove

app = FastAPI(title="Luvia CV Service")
SEG_MODEL_ID = "mattmdjaga/segformer_b2_clothes"
MODEL_ID = "patrickjohncyh/fashion-clip"
TEMPLATE = "a photo of {}"
LOW_CONF = 0.45
CLOSE_GAP = 0.15

# ── Model bir kez yüklenir (servis açılışında, her istekte değil) ──
print("[i] FashionCLIP yükleniyor...")
_model = CLIPModel.from_pretrained(MODEL_ID)
_processor = CLIPProcessor.from_pretrained(MODEL_ID)
_model.eval()
print("[i] Model hazır.")

print("[i] Segmentasyon modeli yükleniyor...")
_seg_model = AutoModelForSemanticSegmentation.from_pretrained(SEG_MODEL_ID)
_seg_processor = SegformerImageProcessor.from_pretrained(SEG_MODEL_ID)
_seg_model.eval()
print("[i] Segmentasyon modeli hazır.")

# seg sınıf id -> (görünen ad, alt-kategori sözlüğü | None, tür)
SEG_PLAN = {
    4:  ("Upper", None, "clothing"),
    6:  ("Lower", None, "clothing"),
    5:  ("Skirt", None, "clothing"),
    7:  ("Dress", None, "clothing"),
    1:  ("Hat",   None, "accessory"),
    16: ("Bag",   None, "accessory"),
}
SHOE_IDS = (9, 10)
MIN_PART_FRAC = 0.003

# ── Firebase Admin başlat (bir kez) ──
BUCKET_NAME = "kombinv1.firebasestorage.app"   # kendi bucket'ın
_cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(_cred, {"storageBucket": BUCKET_NAME})
_bucket = storage.bucket()
print("[i] Firebase Storage bağlı.")

# ── Etiketler: prompt -> .NET ENUM İSMİ (birebir eşleşmeli!) ──
CATEGORY = {
    "a t-shirt": "TShirt", "a long-sleeve shirt": "Shirt", "a sweater": "Sweater",
    "a hoodie or sweatshirt": "Hoodie", "a cardigan": "Cardigan", "a jacket": "Jacket",
    "a coat": "Coat", "a blazer": "Blazer", "jeans": "Jeans",
    "trousers or pants": "Pants", "shorts": "Shorts", "a skirt": "Skirt",
    "a dress": "Dress", "sweatpants": "Sweatpants", "sneakers": "Sneakers",
    "boots": "Boots", "high heels": "Heels", "sandals": "Sandals",
    "a hat or cap": "Hat", "a bag or handbag": "Bag",
    "a necklace": "Necklace", "earrings": "Earrings", "a ring": "Ring",
    "a bracelet": "Bracelet", "a wristwatch": "Watch", "a brooch": "Brooch",
}
STYLE = {
    "a casual everyday clothing item": "Casual", "a streetwear fashion item": "Streetwear",
    "a classic elegant clothing item": "Classic", "an athletic sporty clothing item": "Sporty",
    "a minimalist clean clothing item": "Minimal", "a bohemian style clothing item": "Bohemian",
}
FORMALITY = {
    "loungewear worn at home": "Loungewear", "casual everyday clothing": "Casual",
    "smart casual clothing": "SmartCasual", "business formal clothing": "Business",
    "elegant formal evening wear": "Formal",
}
SEASON = {
    "lightweight clothing for hot summer weather": "Summer",
    "warm heavy clothing for cold winter weather": "Winter",
    "mid-season clothing for mild weather": "MidSeason",
}
PATTERN = {
    "solid color clothing with no pattern": "Solid", "striped clothing": "Striped",
    "plaid or checkered clothing": "Plaid", "floral patterned clothing": "Floral",
    "clothing with a graphic print": "Graphic",
}
MATERIAL = {
    "denim clothing": "Denim", "leather clothing": "Leather",
    "knitted wool clothing": "KnitWool", "cotton clothing": "Cotton", "linen clothing": "Linen",
}
FIT = {
    "slim fit tight clothing": "Slim", "regular fit clothing": "Regular",
    "oversized loose baggy clothing": "Oversized",
}
JEWELRY_TYPE = {
    "a pendant necklace": "Pendant", "a chain necklace": "Chain", "a choker necklace": "Choker",
    "hoop earrings": "Hoop", "stud earrings": "Stud", "a bangle bracelet": "Bangle", "a cuff bracelet": "Cuff",
}
JEWELRY_MATERIAL = {
    "gold jewelry": "Gold", "silver jewelry": "Silver", "rose gold jewelry": "RoseGold",
    "pearl jewelry": "Pearl", "gemstone jewelry": "Gemstone", "beaded jewelry": "Beaded",
}

PART_ATTRS = {
    "clothing": [("Style", STYLE), ("Formality", FORMALITY), ("Season", SEASON),
                 ("Pattern", PATTERN), ("Material", MATERIAL), ("Fit", FIT)],
    "shoes":    [("Style", STYLE), ("Season", SEASON), ("Material", MATERIAL)],
    "accessory":[("Style", STYLE), ("Material", MATERIAL)],
    "jewelry":  [("JewelryType", JEWELRY_TYPE), ("JewelryMaterial", JEWELRY_MATERIAL), ("Style", STYLE)],
}
SHOE_LABELS = {"Sneakers", "Boots", "Heels", "Sandals"}
ACCESSORY_LABELS = {"Hat", "Bag"}
JEWELRY_LABELS = {"Necklace", "Earrings", "Ring", "Bracelet", "Watch", "Brooch"}
# Üst giyimin katmanlı olup olmadığını tespit (sadece clothing/üst için sorulur)
LAYERING = {
    "a jacket or cardigan worn over another top": "layered",
    "a single top worn alone": "single",
}

def kind_for(cat):
    if cat in SHOE_LABELS: return "shoes"
    if cat in JEWELRY_LABELS: return "jewelry"
    if cat in ACCESSORY_LABELS: return "accessory"
    return "clothing"


# ── İstek/yanıt sözleşmesi ──
class AnalyzeRequest(BaseModel):
    imageUrl: str


class AnalyzeResponse(BaseModel):
    category: str
    color: str
    processedImageUrl: str | None = None
    isLayered: bool = False  
    style: str | None = None
    formality: str | None = None
    season: str | None = None
    pattern: str | None = None
    material: str | None = None
    fit: str | None = None
    jewelryType: str | None = None
    jewelryMaterial: str | None = None
    lowConfidenceFields: list[str] = []


def download_image(url: str) -> Image.Image:
    try:
        resp = requests.get(url, timeout=15)
        resp.raise_for_status()
        return Image.open(BytesIO(resp.content)).convert("RGB")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Görüntü indirilemedi: {e}")


def classify(img, prompt_to_label):
    """Bir attribute grubunu sınıflandır: (en iyi etiket, olasılık, kararsız_mı)."""
    prompts = [TEMPLATE.format(p) for p in prompt_to_label]
    inputs = _processor(text=prompts, images=img, return_tensors="pt", padding=True)
    with torch.no_grad():
        probs = _model(**inputs).logits_per_image.softmax(dim=1)[0].tolist()
    labels = list(prompt_to_label.values())
    ranked = sorted(zip(labels, probs), key=lambda x: -x[1])
    (l1, p1), (_, p2) = ranked[0], ranked[1]
    low = p1 < LOW_CONF or (p1 - p2) < CLOSE_GAP
    return l1, p1, low


def dominant_color(img):
    """Merkez bölgeden baskın rengi çıkarıp .NET ColorName enum'una çevirir."""
    w, h = img.size
    cw, ch = int(w * 0.4), int(h * 0.4)
    patch = img.crop(((w - cw) // 2, (h - ch) // 2, (w + cw) // 2, (h + ch) // 2)).resize((120, 120))
    q = patch.quantize(colors=5, method=Image.MEDIANCUT)
    palette = q.getpalette()
    idx = sorted(q.getcolors(), reverse=True)[0][1]
    rgb = tuple(palette[idx * 3: idx * 3 + 3])
    return color_name(rgb)


def color_name(rgb):
    r, g, b = [c / 255.0 for c in rgb]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    H = h * 360.0
    if s < 0.15:
        if v < 0.22: return "Black"
        if v < 0.70: return "Gray"
        return "White"
    if v < 0.12: return "Black"
    if 20 <= H <= 70 and s < 0.35 and v > 0.60:
        return "Cream" if v > 0.85 else "Beige"
    if 40 <= H <= 90 and v < 0.60: return "Khaki"
    if H < 15 or H >= 345: return "Red" if v >= 0.50 else "Burgundy"
    if H < 45: return "Orange" if v >= 0.50 else "Brown"
    if H < 65: return "Yellow"
    if H < 160: return "Green"
    if H < 195: return "Turquoise"
    if H < 255: return "Blue" if v >= 0.50 else "Navy"
    if H < 290: return "Purple"
    return "Pink" if v > 0.60 else "Purple"


@app.get("/health")
def health():
    return {"status": "ok"}

def remove_background(img: Image.Image) -> Image.Image:
    """Arka planı siler, RGBA (şeffaf) döndürür."""
    return remove(img).convert("RGBA")


def upload_to_storage(img: Image.Image) -> str:
    """İşlenmiş görüntüyü Firebase Storage'a yükler, erişilebilir URL döndürür."""
    buffer = BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)

    blob = _bucket.blob(f"processed/{uuid.uuid4()}.png")
    blob.upload_from_file(buffer, content_type="image/png")

    # make_public yerine imzalı URL (uniform bucket access ile de çalışır)
    from datetime import timedelta
    url = blob.generate_signed_url(expiration=timedelta(days=365), method="GET")
    return url

@app.post("/analyze", response_model=AnalyzeResponse)
def analyze(req: AnalyzeRequest):
    img = download_image(req.imageUrl)

    # 1) Kategori + tür
    category, _, cat_low = classify(img, CATEGORY)
    kind = kind_for(category)

    # 2) Attribute'lar
    result = {"category": category, "color": dominant_color(img)}
        # Sadece dış-giyim türü parçalarda katman tespiti (ceket/mont/hırka/blazer)
    OUTERWEAR = {"Jacket", "Coat", "Cardigan", "Blazer"}
    if category in OUTERWEAR:
        result["isLayered"] = detect_layering(img)
    low_fields = []
    if cat_low:
        low_fields.append("Category")
    for field, group in PART_ATTRS[kind]:
        label, _, low = classify(img, group)
        key = field[0].lower() + field[1:]
        result[key] = label
        if low:
            low_fields.append(field)
    result["lowConfidenceFields"] = low_fields

    # 3) Arka planı sil + Storage'a yükle
    try:
        print(">>> Arka plan siliniyor + Storage'a yükleniyor...")
        cutout = remove_background(img)
        result["processedImageUrl"] = upload_to_storage(cutout)
        print(f">>> Yuklendi: {result['processedImageUrl']}")
    except Exception as e:
        print(f">>> HATA: {e}")
        result["processedImageUrl"] = None

    return AnalyzeResponse(**result)


def segment(img):
    inputs = _seg_processor(images=img, return_tensors="pt")
    with torch.no_grad():
        logits = _seg_model(**inputs).logits
    up = F.interpolate(logits, size=(img.height, img.width), mode="bilinear", align_corners=False)
    return up.argmax(dim=1)[0].cpu().numpy()


def cutout_from_mask(img, mask, pad=6):
    # Maskede birden fazla ayrı bölge varsa (yansıma/ikinci açı), sadece EN BÜYÜĞÜNÜ al
    labeled, num = ndimage.label(mask)
    if num > 1:
        sizes = ndimage.sum(mask, labeled, range(1, num + 1))
        largest = np.argmax(sizes) + 1
        mask = (labeled == largest)
        print(f">>> {num} ayrı bölge bulundu, en büyüğü seçildi")

    ys, xs = np.where(mask)
    if len(ys) == 0:
        return None
    h, w = mask.shape
    y0 = max(0, int(ys.min()) - pad); y1 = min(h, int(ys.max()) + 1 + pad)
    x0 = max(0, int(xs.min()) - pad); x1 = min(w, int(xs.max()) + 1 + pad)
    rgba = img.convert("RGBA")
    alpha = Image.fromarray((mask.astype("uint8") * 255), "L")
    from PIL import ImageFilter
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))
    rgba.putalpha(alpha)
    return rgba.crop((x0, y0, x1, y1))


def analyze_part_image(cutout, category_from_seg, kind):
    """Segment kesimini analiz eder. YÜKLEME YAPMAZ — cutout'u da döndürür (sonra paralel yüklenir)."""
    white = Image.new("RGB", cutout.size, (255, 255, 255))
    white.paste(cutout, mask=cutout.split()[-1])

    category, _, cat_low = classify(white, CATEGORY)
    result = {"category": category, "color": dominant_color(white)}

    OUTERWEAR = {"Jacket", "Coat", "Cardigan", "Blazer"}
    if category in OUTERWEAR:
        result["isLayered"] = detect_layering(white)

    low_fields = ["Category"] if cat_low else []
    for field, group in PART_ATTRS[kind_for(category)]:
        label, _, low = classify(white, group)
        key = field[0].lower() + field[1:]
        result[key] = label
        if low:
            low_fields.append(field)

    result["lowConfidenceFields"] = low_fields
    result["processedImageUrl"] = None  # yükleme sonra paralel yapılacak
    return result, cutout   # ← cutout'u da döndür

class FullbodyResponse(BaseModel):
    items: list[AnalyzeResponse] = []


@app.post("/analyze-fullbody", response_model=FullbodyResponse)
def analyze_fullbody(req: AnalyzeRequest):
    t0 = time.time()
    img = download_image(req.imageUrl)
    t_download = time.time()

    seg = segment(img)
    min_px = int(MIN_PART_FRAC * seg.shape[0] * seg.shape[1])
    t_segment = time.time()

    # ── AŞAMA 1: Tüm parçaları SIRALI analiz et (yükleme yok), cutout'ları biriktir ──
    results = []   # (result_dict, cutout) listesi

    for cid, (label, _, kind) in SEG_PLAN.items():
        mask = (seg == cid)
        if mask.sum() < min_px:
            continue
        cutout = cutout_from_mask(img, mask)
        if cutout is None:
            continue
        print(f">>> Parça bulundu: {label}")
        results.append(analyze_part_image(cutout, label, kind))

    shoe_mask = np.isin(seg, SHOE_IDS)
    if shoe_mask.sum() >= min_px:
        cutout = cutout_from_mask(img, shoe_mask)
        if cutout is not None:
            print(">>> Parça bulundu: Shoes")
            results.append(analyze_part_image(cutout, "Shoes", "shoes"))

    t_analyze = time.time()

    # ── AŞAMA 2: Tüm görselleri PARALEL yükle ──
    def upload_one(cutout):
        try:
            return upload_to_storage(cutout)
        except Exception as e:
            print(f">>> Parça yükleme hatası: {e}")
            return None

    cutouts = [c for (_, c) in results]
    with ThreadPoolExecutor(max_workers=8) as executor:
        urls = list(executor.map(upload_one, cutouts))

    # URL'leri sonuçlara yaz
    items = []
    for (result, _), url in zip(results, urls):
        result["processedImageUrl"] = url
        items.append(AnalyzeResponse(**result))

    t_upload = time.time()

    # ── ÖLÇÜM ──
    print(f">>> SÜRELER: indir={t_download-t0:.1f}s  segment={t_segment-t_download:.1f}s  "
          f"analiz={t_analyze-t_segment:.1f}s  yükle(paralel)={t_upload-t_analyze:.1f}s  "
          f"TOPLAM={t_upload-t0:.1f}s  ({len(items)} parça)")

    return FullbodyResponse(items=items)

def detect_layering(img) -> bool:
    """Üst giyim katmanlı mı (dışta ceket/hırka + altında başka üst)?"""
    label, p1, low = classify(img, LAYERING)
    # 'layered' belirgin şekilde öndeyse katmanlı say (kararsızsa güvenli tarafta: değil)
    return label == "layered" and not low

class DeleteImageRequest(BaseModel):
    imageUrl: str

@app.post("/delete-image")
def delete_image(req: DeleteImageRequest):
    """processed/ altındaki bir görseli Storage'dan siler."""
    try:
        # İmzalı URL'den blob yolunu çıkar: .../processed/<uuid>.png?...
        from urllib.parse import urlparse, unquote
        path = urlparse(req.imageUrl).path          # /kombinv1.../processed/xxx.png
        # bucket adından sonrasını al
        if "/processed/" in path:
            blob_path = "processed/" + path.split("/processed/")[1]
            blob = _bucket.blob(blob_path)
            blob.delete()
            print(f">>> Silindi: {blob_path}")
            return {"deleted": True}
        return {"deleted": False, "reason": "processed/ yolu bulunamadı"}
    except Exception as e:
        print(f">>> Görsel silme hatası: {e}")
        return {"deleted": False, "reason": str(e)}    