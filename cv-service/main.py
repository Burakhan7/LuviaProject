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
    # ── Nötrler (elif çoğunu yakalar ama yedek referans) ──
    "Black":         (20, 20, 20),
    "Gray":          (128, 128, 128),
    "White":         (240, 240, 240),
    "Cream":         (245, 238, 220),
    "Beige":         (225, 205, 175),
    "Khaki":         (140, 130, 90),
    "Khaki_light":   (170, 160, 120),   # açık haki

    # ── Kırmızı ailesi ──
    "Red":           (200, 30, 30),
    "Red_dark":      (150, 25, 25),     # koyu kırmızı
    "Red_bright":    (225, 45, 45),     # parlak kırmızı
    "Burgundy":      (110, 30, 40),
    "Burgundy_light":(150, 50, 60),     # açık bordo

    # ── Turuncu ──
    "Orange":        (230, 125, 40),
    "Orange_dark":   (200, 100, 30),    # koyu turuncu / kiremit
    "Orange_light":  (245, 165, 90),    # açık turuncu / şeftali

    # ── Kahve ──
    "Brown":         (110, 70, 40),
    "Brown_dark":    (75, 50, 35),      # koyu kahve
    "Brown_light":   (160, 120, 85),    # açık kahve / taba

    # ── Sarı ──
    "Yellow":        (235, 210, 50),
    "Yellow_dark":   (200, 175, 40),    # hardal
    "Yellow_light":  (245, 230, 130),   # açık sarı

    # ── Yeşil ──
    "Green":         (60, 140, 70),
    "Green_dark":    (45, 80, 45),      # koyu / orman yeşili
    "Green_light":   (140, 200, 130),   # açık yeşil
    "Green_olive":   (110, 120, 60),    # zeytin / haki-yeşil
    "Green_mint":    (170, 220, 190),   # nane / mint

    # ── Turkuaz ──
    "Turquoise":     (60, 185, 185),
    "Turquoise_dark":(40, 130, 135),    # koyu turkuaz / petrol

    # ── Mavi ──
    "Blue":          (45, 105, 200),
    "Blue_dark":     (35, 75, 150),     # koyu mavi
    "Blue_light":    (120, 175, 225),   # açık mavi
    "Blue_ice":      (195, 218, 235),   # buz mavisi
    "Blue_steel":    (100, 130, 165),   # çelik / griye kayan mavi
    "Navy":          (25, 35, 80),      # lacivert

    # ── Mor / Pembe ──
    "Purple":        (115, 60, 145),
    "Purple_dark":   (80, 45, 105),     # koyu mor
    "Lilac":         (190, 165, 215),   # lila / açık mor
    "Pink":          (230, 115, 165),
    "Pink_light":    (245, 195, 215),   # pudra pembe
    "Pink_hot":      (230, 70, 130),    # fuşya / canlı pembe
}

_COLOR_ALIAS = {
    # Khaki
    "Khaki_light":    "Khaki",
    # Kırmızı
    "Red_dark":       "Red",
    "Red_bright":     "Red",
    "Burgundy_light": "Burgundy",
    # Turuncu
    "Orange_dark":    "Orange",
    "Orange_light":   "Orange",
    # Kahve
    "Brown_dark":     "Brown",
    "Brown_light":    "Brown",
    # Sarı
    "Yellow_dark":    "Yellow",
    "Yellow_light":   "Yellow",
    # Yeşil
    "Green_dark":     "Green",
    "Green_light":    "Green",
    "Green_olive":    "Green",
    "Green_mint":     "Green",
    # Turkuaz
    "Turquoise_dark": "Turquoise",
    # Mavi
    "Blue_dark":      "Blue",
    "Blue_light":     "Blue",
    "Blue_ice":       "Blue",
    "Blue_steel":     "Blue",
    # Mor / Pembe
    "Purple_dark":    "Purple",
    "Lilac":          "Purple",
    "Pink_light":     "Pink",
    "Pink_hot":       "Pink",
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

    # ═══ 1. ÇOK KOYU BÖLGE (L < 22) ═══
    # Siyah mı, koyu kahve mi, koyu yeşil mi, lacivert mi?
    if L < 22:
        # Yeşil tarafı (a belirgin negatif) → koyu yeşil
        if a < -3 and abs(a) >= abs(b) * 0.6:
            return "Green"
        # Maviye kaçan koyu → lacivert
        if b < -6:
            return "Navy"
        # Sıcak ton (a,b pozitif, belirgin) → koyu kahve
        if a > 6 and b > 6:
            return "Brown"
        # Renksiz koyu → siyah
        return "Black"

    # ═══ 2. GERÇEK NÖTR BÖLGE ═══
    # Chroma düşük VE hiçbir kanal belirgin değilse nötr (renksiz)
    # Ama a veya b belirginse (|a|>6 gibi), düşük chroma'da bile RENKLIDIR
    is_truly_neutral = chroma < 10 and abs(a) < 6 and abs(b) < 8
    if is_truly_neutral:
        if L < 40:
            return "Black"        # koyu nötr → siyah (koyu gri nadir, siyah yaygın)
        elif L < 62:
            return "Gray"
        elif L < 78:
            if b > 10:
                return "Beige"
            return "White" if L >= 70 else "Gray"
        else:
            return "Beige" if b > 12 else "White"

    # ═══ 3. DÜŞÜK DOYGUNLUK (chroma 10-18) — soluk ama belirgin tonlar ═══
    if chroma < 18:
        # Çok açık + hala düşük doygunluk → beyaz/açık nötr (renk deme)
        if L > 75 and chroma < 13:
            return "Beige" if b > 10 else "White"

        # Mavi-yeşil ayrımı
        if a < -3:
            if b < -6:
                return "Turquoise"
            return "Green"
        if b < -5:
            return "Blue"
        if a >= 2 and b > 6:
            # Sıcak soluk ton: beige mi khaki mi
            # Beige daha açık ve sarımsı (yüksek L), khaki daha koyu/mat
            if L >= 62:
                return "Beige"       # açık sıcak → bej
            return "Khaki"           # koyu sıcak → haki
        if a > 5 and b < 4:
            return "Pink"
        if L > 75:
            return "Beige" if b > 8 else "White"
        return "Gray"

    # ═══ 4. DOYGUN RENKLER (zengin palet + LAB en yakın) ═══
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
    import colorsys
    rgba = img.convert("RGBA")
    arr = np.array(rgba)

    alpha = arr[:, :, 3]
    rgb = arr[:, :, :3]

    mask = alpha > 160
    pixels = rgb[mask].astype("float32")

    if len(pixels) == 0:
        return color_name((128, 128, 128))

    # ── YÖNTEM 3: Aydınlık pikselleri seç, gölgeleri at ──
    luminance = 0.299 * pixels[:, 0] + 0.587 * pixels[:, 1] + 0.114 * pixels[:, 2]
    # En parlak %55'lik dilimi al (gölgeli alt %45 elenir)
    threshold = np.percentile(luminance, 45)
    bright = pixels[luminance >= threshold]
    if len(bright) < 10:
        bright = pixels  # çok az kalırsa hepsini kullan

    # ── YÖNTEM 1: HSV'ye çevir, parlaklığı (V) yok sayarak baskın TON+DOYGUNLUK bul ──
    # Her pikseli HSV'ye çevir
    r = bright[:, 0] / 255.0
    g = bright[:, 1] / 255.0
    b = bright[:, 2] / 255.0
    maxc = np.maximum(np.maximum(r, g), b)
    minc = np.minimum(np.minimum(r, g), b)
    v = maxc
    delta = maxc - minc
    s = np.where(maxc > 0, delta / (maxc + 1e-6), 0)

    # Hue hesabı (0-360)
    hue = np.zeros_like(maxc)
    mask_delta = delta > 1e-6
    # Kırmızı baskın
    rc = (maxc == r) & mask_delta
    hue[rc] = (60 * ((g[rc] - b[rc]) / delta[rc]) + 360) % 360
    # Yeşil baskın
    gc = (maxc == g) & mask_delta
    hue[gc] = (60 * ((b[gc] - r[gc]) / delta[gc]) + 120) % 360
    # Mavi baskın
    bc = (maxc == b) & mask_delta
    hue[bc] = (60 * ((r[bc] - g[bc]) / delta[bc]) + 240) % 360

    # Ortalama H, S (dairesel ortalama hue) — parlaklık V'yi yüksek sabit tut
    # Hue dairesel olduğu için sin/cos ile ortalama
    hue_rad = np.radians(hue)
    mean_sin = np.mean(np.sin(hue_rad))
    mean_cos = np.mean(np.cos(hue_rad))
    mean_hue = (np.degrees(np.arctan2(mean_sin, mean_cos)) + 360) % 360
    mean_s = float(np.mean(s))
    # V'yi (parlaklık) yüksek sabit al — gölge etkisini nötrle
    fixed_v = float(np.percentile(v, 75))  # üst çeyrek parlaklık

    # HSV → RGB (normalize edilmiş renk)
    nr, ng, nb = colorsys.hsv_to_rgb(mean_hue / 360.0, mean_s, fixed_v)
    dominant_rgb = (int(nr * 255), int(ng * 255), int(nb * 255))

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