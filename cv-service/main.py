# main.py — Luvia CV servisi (gerçek FashionCLIP + renk analizi)
import colorsys
from io import BytesIO

import requests
import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from PIL import Image, ImageOps
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
from PIL import Image, ImageFilter

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
        img = Image.open(BytesIO(resp.content))
        img = ImageOps.exif_transpose(img)
        return img.convert("RGB")
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


_COLOR_REFS = {
    # ── Nötrler ──
    "Black":        (15, 15, 15),
    "Gray_dark":    (70, 70, 70),
    "Gray":         (128, 128, 128),
    "Gray_light":   (190, 190, 190),
    "White":        (245, 245, 245),       # 225'ten 245'e çekildi
    "Cream":        (245, 238, 220),
    "Beige":        (225, 205, 175),
    "Khaki":        (140, 130, 90),

    # ── Yeşil ──
    "Green":        (60, 140, 70),
    "Green_dark":   (45, 75, 45),
    "Green_light":  (140, 200, 130),
    "Green_mint":   (190, 230, 205),       # Açık nane/mint yeşili

    # ── Kırmızı / Bordo ──
    "Red":          (200, 30, 30),
    "Burgundy":     (110, 30, 40),

    # ── Turuncu / Kahve / Sarı ──
    "Orange":       (230, 125, 40),
    "Brown":        (110, 70, 40),
    "Brown_dark":   (65, 45, 30),
    "Yellow":       (235, 210, 50),
    "Yellow_light": (245, 235, 160),       # Açık pastel sarı

    # ── Mavi ──
    "Blue":         (45, 105, 200),
    "Blue_light":   (130, 185, 230),       # Bebek mavisi
    "Blue_ice":     (195, 218, 235),       # (199, 217, 229) için tam eşleşen buz mavisi
    "Navy":         (25, 35, 80),
    "Turquoise":    (60, 185, 185),

    # ── Mor / Pembe ──
    "Purple":       (115, 60, 145),
    "Lilac":        (205, 185, 225),       # Açık lila
    "Pink":         (230, 115, 165),
    "Pink_light":   (245, 195, 215),       # Pudra pembe
}

_COLOR_ALIAS = {
    "Gray_dark":    "Gray",
    "Gray_light":   "Gray",
    "Green_dark":   "Green",
    "Green_light":  "Green",
    "Green_mint":   "Green",
    "Brown_dark":   "Brown",
    "Yellow_light": "Yellow",
    "Blue_light":   "Blue",
    "Blue_ice":     "Blue",
    "Lilac":        "Purple",
    "Pink_light":   "Pink",
}

# Referansların LAB karşılıklarını bir kez hesapla (açılışta)
def _rgb_to_lab(rgb):
    import numpy as np
    from skimage.color import rgb2lab
    arr = np.array([[[c / 255.0 for c in rgb]]])  # (1,1,3) normalize
    return rgb2lab(arr)[0, 0]  # [L, a, b]

_COLOR_REFS_LAB = {name: _rgb_to_lab(rgb) for name, rgb in _COLOR_REFS.items()}


def color_name(rgb):
    import numpy as np
    lab = _rgb_to_lab(rgb)
    L, a, b = lab[0], lab[1], lab[2]
    chroma = float(np.sqrt(a * a + b * b))

    print(f">>> RGB:{rgb} L={L:.0f} a={a:.0f} b={b:.0f} chroma={chroma:.0f}")

    # ── 1. KOYU BÖLGE (L < 28) ──
    if L < 28:
        if b < -6:
            return "Navy"
        if b > 4 and a > 1:
            return "Brown"
        return "Black"

    # ── 2. ÇOK AÇIK NÖTRLER / BEYAZ (L >= 72) ──
    # Sadece gerçekten parlak ve açık olanlar buraya girer
    if L >= 72 and chroma < 7:
        if b > 9:
            return "Cream" if L > 85 else "Beige"
        if b < -4:
            return "Blue"     # Çok açık buz mavisi
        return "White"

    # ── 3. HAFİF RENKLİ / ALT TONLU GRİLER (chroma >= 2 ve L < 72) ──
    # Maviye çalan gri / kot mavisi / antrasit-mavi
    if b < -1.5 and a <= 0:
        return "Blue"

    # Yeşile çalan gri / adaçayı / zeytin
    if a < -2 and (a <= b):
        return "Green"

    # Sıcak tonlu / kahveye / beje çalan gri
    if b > 4:
        if L < 45 and a > 0:
            return "Brown"
        return "Beige"

    # Pembeye / mora çalan hafif ton
    if a > 4 and b < 3:
        return "Pink"

    # ── 4. GERÇEK / TAM NÖTR GRİ (chroma < 6 ve belirgin alt tonu olmayanlar) ──
    if chroma < 6:
        return "Gray"

    # ── 5. DOYGUN RENKLER (CIELAB En Yakın Referans) ──
    best_name = "Gray"
    best_dist = float("inf")
    for name, ref_lab in _COLOR_REFS_LAB.items():
        dist = float(np.sqrt(np.sum((lab - ref_lab) ** 2)))
        if dist < best_dist:
            best_dist = dist
            best_name = name

    return _COLOR_ALIAS.get(best_name, best_name)


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

    # 1) Arka planı sil (Cutout oluştur)
    try:
        print(">>> Arka plan siliniyor...")
        cutout = remove_background(img)
    except Exception as e:
        print(f">>> Arka plan silme hatası: {e}")
        cutout = img.convert("RGBA")

    # 2) Kategori + tür
    # CLIP sınıflandırması için beyaz arka planlı versiyonunu oluştur
    white_bg = Image.new("RGB", cutout.size, (255, 255, 255))
    white_bg.paste(cutout, mask=cutout.split()[-1] if cutout.mode == "RGBA" else None)

    category, _, cat_low = classify(white_bg, CATEGORY)
    kind = kind_for(category)

    # 3) Attribute'lar ve DOĞRU Renk Analizi (dominant_color_masked ile)
    result = {
        "category": category, 
        "color": dominant_color_masked(cutout)  # ← Maskelenmiş piksel analizi
    }

    # Sadece dış-giyim türü parçalarda katman tespiti (ceket/mont/hırka/blazer)
    OUTERWEAR = {"Jacket", "Coat", "Cardigan", "Blazer"}
    if category in OUTERWEAR:
        result["isLayered"] = detect_layering(white_bg)

    low_fields = []
    if cat_low:
        low_fields.append("Category")

    for field, group in PART_ATTRS[kind]:
        label, _, low = classify(white_bg, group)
        key = field[0].lower() + field[1:]
        result[key] = label
        if low:
            low_fields.append(field)

    result["lowConfidenceFields"] = low_fields

    # 4) Storage'a yükle
    try:
        print(">>> Storage'a yükleniyor...")
        result["processedImageUrl"] = upload_to_storage(cutout)
        print(f">>> Yüklendi: {result['processedImageUrl']}")
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


def cutout_from_mask(img: Image.Image, mask: np.ndarray, pad: int = 6):
    """Segmentasyon maskesine göre kıyafeti kesip şeffaf RGBA döndürür."""
    # 1. Maske boyutunu orijinal görselin boyutuna eşitle (Güvenlik adımı)
    if mask.shape != (img.height, img.width):
        mask_img = Image.fromarray(mask.astype("uint8") * 255, mode="L")
        mask_img = mask_img.resize(img.size, resample=Image.NEAREST)
        mask = np.array(mask_img) > 128

    ys, xs = np.where(mask)
    if len(ys) == 0:
        return None

    h, w = mask.shape
    y0 = max(0, int(ys.min()) - pad)
    y1 = min(h, int(ys.max()) + 1 + pad)
    x0 = max(0, int(xs.min()) - pad)
    x1 = min(w, int(xs.max()) + 1 + pad)

    rgba = img.convert("RGBA")
    
    # Maskeyi Alpha kanalına dönüştür ve hafif yumuşat
    alpha = Image.fromarray((mask.astype("uint8") * 255), mode="L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    rgba.putalpha(alpha)

    # Sadece kıyafetin olduğu alana crop uygula
    return rgba.crop((x0, y0, x1, y1))


def analyze_part_image(cutout, category_from_seg, kind):
    """Segment kesimini analiz eder. YÜKLEME YAPMAZ — cutout'u da döndürür (sonra paralel yüklenir)."""
    white = Image.new("RGB", cutout.size, (255, 255, 255))
    white.paste(cutout, mask=cutout.split()[-1])

    category, _, cat_low = classify(white, CATEGORY)
    result = {"category": category, "color": dominant_color_masked(cutout)} 

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

def dominant_color_masked(img: Image.Image):
    rgba = img.convert("RGBA")
    arr = np.array(rgba)
    
    alpha = arr[:, :, 3]
    rgb = arr[:, :, :3]

    mask = alpha > 160
    pixels = rgb[mask]

    if len(pixels) == 0:
        return color_name((128, 128, 128))

    # Kumaş kıvrımlarındaki derin gölgeleri elemek için parlaklık (Luminance) filtresi
    # Y = 0.299R + 0.587G + 0.114B
    luminance = 0.299 * pixels[:, 0] + 0.587 * pixels[:, 1] + 0.114 * pixels[:, 2]
    median_lum = np.median(luminance)
    
    # Çok karanlık olmayan (gölgede kalmamış) ana yüzey piksellerini al
    bright_enough = luminance >= (median_lum * 0.85)
    valid_pixels = pixels[bright_enough]

    if len(valid_pixels) == 0:
        valid_pixels = pixels

    strip = valid_pixels.reshape(1, -1, 3).astype("uint8")
    strip_img = Image.fromarray(strip, mode="RGB")

    q = strip_img.quantize(colors=5, method=Image.MEDIANCUT)
    palette = q.getpalette()
    colors = q.getcolors()

    if not colors:
        return color_name((128, 128, 128))

    idx = sorted(colors, reverse=True)[0][1]
    dominant_rgb = tuple(palette[idx * 3 : idx * 3 + 3])

    return color_name(dominant_rgb)

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

    """
    Gray World beyaz dengesi: renkli ışık kaymasını (sarı lamba, mavi gölge) nötrler.
    strength: 0=etki yok, 1=tam düzeltme. Aşırı düzeltmeyi önlemek için <1 tutulur.
    """
    import numpy as np
    arr = np.array(img.convert("RGB")).astype(np.float32)

    # Her kanalın ortalaması
    r_mean = arr[:, :, 0].mean()
    g_mean = arr[:, :, 1].mean()
    b_mean = arr[:, :, 2].mean()
    gray = (r_mean + g_mean + b_mean) / 3.0

    if r_mean < 1 or g_mean < 1 or b_mean < 1:
        return img  # neredeyse siyah, dokunma

    # Her kanalı griye çekecek ölçek — ama strength ile sınırlı
    r_scale = 1 + (gray / r_mean - 1) * strength
    g_scale = 1 + (gray / g_mean - 1) * strength
    b_scale = 1 + (gray / b_mean - 1) * strength

    arr[:, :, 0] *= r_scale
    arr[:, :, 1] *= g_scale
    arr[:, :, 2] *= b_scale

    arr = np.clip(arr, 0, 255).astype("uint8")
    from PIL import Image
    return Image.fromarray(arr, "RGB")          