#!/usr/bin/env python3
# ── Luvia BOYDAN fotograf renk testi (cv-service metodu + k-NN renk) ──
# Ayakkabi esigi dusuruldu (boydan fotoda ayakkabi kucuk kalir).
# Kullanim: python test_fullbody.py <foto>

import sys, json, os
import numpy as np
from PIL import Image, ImageFilter
import torch
import torch.nn.functional as F
from transformers import SegformerImageProcessor, AutoModelForSemanticSegmentation
from skimage.color import rgb2lab
from collections import Counter

REFS_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'color_refs.json')
refs = json.load(open(REFS_PATH))
ref_labs = np.array([r[0] for r in refs]); ref_cats = [r[1] for r in refs]

def to_lab(rgb): return rgb2lab(np.array([[[c/255.0 for c in rgb]]]))[0,0]
def classify_knn(rgb, k=7):
    d = np.sqrt(np.sum((ref_labs - to_lab(rgb))**2, axis=1))
    votes = Counter(ref_cats[i] for i in np.argsort(d)[:k])
    return votes.most_common(1)[0][0], dict(votes)

SEG_MODEL_ID = "mattmdjaga/segformer_b2_clothes"
print("[i] Model yukleniyor...")
seg_model = AutoModelForSemanticSegmentation.from_pretrained(SEG_MODEL_ID)
seg_proc  = SegformerImageProcessor.from_pretrained(SEG_MODEL_ID)
seg_model.eval(); print("[i] Hazir.\n")

PARTS = {4:"Ust giyim", 6:"Alt giyim", 5:"Etek", 7:"Elbise"}
SHOE_IDS = [9, 10]

def segment(img):
    inputs = seg_proc(images=img, return_tensors="pt")
    with torch.no_grad():
        logits = seg_model(**inputs).logits
    up = F.interpolate(logits, size=(img.height, img.width), mode="bilinear", align_corners=False)
    return up.argmax(dim=1)[0].cpu().numpy()

def cutout_from_mask(img, mask, pad=6):
    ys, xs = np.where(mask)
    if len(ys) == 0: return None
    h, w = mask.shape
    y0,y1 = max(0,int(ys.min())-pad), min(h,int(ys.max())+1+pad)
    x0,x1 = max(0,int(xs.min())-pad), min(w,int(xs.max())+1+pad)
    rgba = img.convert("RGBA")
    alpha = Image.fromarray((mask.astype("uint8")*255),mode="L").filter(ImageFilter.GaussianBlur(0.8))
    rgba.putalpha(alpha)
    return rgba.crop((x0,y0,x1,y1))

def dominant_rgb(cutout):
    arr = np.array(cutout.convert("RGBA"))
    mask = arr[:,:,3] > 200          # daha kati alpha -> kenar/arka plan sizmasi az
    pixels = arr[:,:,:3][mask].astype("float32")
    if len(pixels) < 20: return None
    # Median-cut ile 6 kumeye ayir
    strip = pixels.reshape(1,-1,3).astype("uint8")
    q = Image.fromarray(strip,"RGB").quantize(colors=6, method=Image.MEDIANCUT)
    pal = q.getpalette()
    colors = q.getcolors()            # [(count, idx), ...]
    total = sum(c for c,_ in colors)
    # Yeterince buyuk (>=%12 alan) kumeler arasindan EN PARLAGINI sec
    # (golgeli buyuk kumeyi atla, aydinlik gercek rengi bul)
    aday = []
    for cnt, idx in colors:
        if cnt < 0.12 * total:        # cok kucuk kumeler (highlight/golge lekesi) ele
            continue
        rgb = pal[idx*3:idx*3+3]
        lum = 0.299*rgb[0]+0.587*rgb[1]+0.114*rgb[2]
        aday.append((lum, tuple(rgb)))
    if not aday:                       # hepsi kucukse en buyugu al
        idx = sorted(colors, reverse=True)[0][1]
        return tuple(pal[idx*3:idx*3+3])
    aday.sort(reverse=True)            # en parlak basta
    return aday[0][1]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Kullanim: python test_fullbody.py <foto>"); sys.exit(1)
    img = Image.open(sys.argv[1]).convert("RGB")
    seg = segment(img)
    total = seg.size
    # Giysi esigi %1, AYAKKABI esigi cok daha dusuk (%0.1) — boydan fotoda kucuk kalir
    min_giysi = int(0.01 * total)
    min_ayakkabi = int(0.001 * total)
    print(f"Fotograf: {sys.argv[1]}\n")
    print("=== PARCALAR + RENK (k-NN) ===")
    found = False

    for cid, ad in PARTS.items():
        mask = (seg == cid)
        if mask.sum() < min_giysi: continue
        cutout = cutout_from_mask(img, mask)
        if cutout is None: continue
        rgb = dominant_rgb(cutout)
        if rgb is None: continue
        cat, votes = classify_knn(rgb)
        print(f"{ad:10s}: RGB{rgb} -> {cat}")
        print(f"            komsular: {votes}")
        found = True

    # Ayakkabi — dusuk esik
    shoe_mask = np.isin(seg, SHOE_IDS)
    if shoe_mask.sum() >= min_ayakkabi:
        cutout = cutout_from_mask(img, shoe_mask)
        if cutout is not None:
            rgb = dominant_rgb(cutout)
            if rgb:
                cat, votes = classify_knn(rgb)
                print(f"{'Ayakkabi':10s}: RGB{rgb} -> {cat}")
                print(f"            komsular: {votes}")
                found = True
    else:
        print(f"(Ayakkabi cok kucuk/yok: {shoe_mask.sum()} piksel, esik {min_ayakkabi})")

    if not found: print("Parca bulunamadi")