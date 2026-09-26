#!/usr/bin/env python3
# ── Luvia SEGMENTASYON DEBUG ──
# Her parcanin maskesini + kesilmis halini PNG olarak kaydeder.
# Boylece "model dogru yeri mi seciyor" gozunle gorursun.
# Kullanim: python test_debug.py <fotograf_yolu>
# Ciktilar: debug_out/ klasorune kaydedilir.

import sys, os
import numpy as np
from PIL import Image, ImageFilter
import torch
import torch.nn.functional as F
from transformers import SegformerImageProcessor, AutoModelForSemanticSegmentation

SEG_MODEL_ID = "mattmdjaga/segformer_b2_clothes"
print("[i] Model yukleniyor...")
seg_model = AutoModelForSemanticSegmentation.from_pretrained(SEG_MODEL_ID)
seg_proc  = SegformerImageProcessor.from_pretrained(SEG_MODEL_ID)
seg_model.eval()
print("[i] Hazir.\n")

# segformer_b2_clothes TUM siniflar (hangi id ne demek)
ALL_LABELS = {
    0:"Background", 1:"Hat", 2:"Hair", 3:"Sunglasses", 4:"Upper-clothes",
    5:"Skirt", 6:"Pants", 7:"Dress", 8:"Belt", 9:"Left-shoe", 10:"Right-shoe",
    11:"Face", 12:"Left-leg", 13:"Right-leg", 14:"Left-arm", 15:"Right-arm",
    16:"Bag", 17:"Scarf",
}

def segment(img):
    inputs = seg_proc(images=img, return_tensors="pt")
    with torch.no_grad():
        logits = seg_model(**inputs).logits
    up = F.interpolate(logits, size=(img.height, img.width),
                       mode="bilinear", align_corners=False)
    return up.argmax(dim=1)[0].cpu().numpy()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Kullanim: python test_debug.py <foto>"); sys.exit(1)
    img = Image.open(sys.argv[1]).convert("RGB")
    seg = segment(img)
    os.makedirs("debug_out", exist_ok=True)

    print(f"Fotograf boyutu: {img.size}")
    print(f"Segmentasyonda BULUNAN siniflar (piksel sayisiyla):\n")
    # Hangi siniflar var, kac piksel
    ids, counts = np.unique(seg, return_counts=True)
    total = seg.size
    for i, c in sorted(zip(ids, counts), key=lambda x:-x[1]):
        ad = ALL_LABELS.get(int(i), f"id{i}")
        pct = 100*c/total
        print(f"  {ad:15s} (id={i}): {pct:.1f}% ({c} piksel)")
        # Her sinif icin maske PNG kaydet (sadece anlamli olanlar >%1)
        if pct >= 1.0 and i != 0:  # background haric
            mask = (seg == i)
            # Kesilmis parca goruntusu
            rgba = img.convert("RGBA")
            alpha = Image.fromarray((mask.astype("uint8")*255), mode="L")
            rgba.putalpha(alpha)
            ys,xs = np.where(mask)
            if len(ys)>0:
                crop = rgba.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1))
                # Beyaz zemine yapistir (gormek icin)
                bg = Image.new("RGB", crop.size, (255,255,255))
                bg.paste(crop, mask=crop.split()[-1])
                bg.save(f"debug_out/{ad}_{i}.png")

    print(f"\n=> debug_out/ klasorune her parcanin kesilmis hali kaydedildi.")
    print("   Ac ve bak: 'Upper-clothes_4.png' gercekten ustu mu gosteriyor?")