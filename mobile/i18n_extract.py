#!/usr/bin/env python3
# ── Luvia i18n otomatik cikarici ──
# Dart dosyasindaki Turkce Text('...') metinlerini bulur:
#  1) Kodda AppLocalizations ile degistirir (const Text -> Text)
#  2) tr_yeni.json (Turkce) + en_yeni.json (Ingilizce, bos) uretir
#
# Kullanim: python i18n_extract.py lib/screens/home_screen.dart

import sys, re, json, os

TURKCE = set("cgiosuCGIOSU" + "çğıöşüÇĞİÖŞÜ")

def turkce_mi(s):
    if any(c in "çğıöşüÇĞİÖŞÜ" for c in s):
        return True
    if ' ' in s and len(s) > 4 and s[0].isupper() and re.search(r'[a-zA-Z]{3}', s):
        return True
    return False

def key_uret(metin, mevcut):
    kelimeler = re.findall(r'[a-zA-ZğüşıöçĞÜŞİÖÇ]+', metin)[:3]
    tr2en = str.maketrans("ğüşıöçĞÜŞİÖÇ", "gusiocGUSIOC")
    kelimeler = [k.translate(tr2en) for k in kelimeler]
    if not kelimeler:
        base = "text"
    else:
        base = kelimeler[0].lower() + ''.join(k.capitalize() for k in kelimeler[1:])
    key = base
    i = 2
    while key in mevcut:
        key = f"{base}{i}"; i += 1
    return key

def main(path):
    with open(path, encoding='utf-8') as f:
        kod = f.read()

    bulunan = {}    # key -> TR metin
    metin2key = {}  # metin -> key

    def rep(m):
        q = m.group('q')
        metin = m.group('t')
        if not turkce_mi(metin):
            return m.group(0)  # dokunma (kod string'i, kategori vs)
        if metin in metin2key:
            key = metin2key[metin]
        else:
            key = key_uret(metin, bulunan)
            bulunan[key] = metin
            metin2key[metin] = key
        return f"Text(AppLocalizations.of(context)!.{key}"

    # const Text('..') veya Text('..') — $ (interpolation) icermeyen basit metinler
    pattern = r"(?:const\s+)?Text\(\s*(?P<q>['\"])(?P<t>(?:(?!(?P=q))[^\\$])*?)(?P=q)"
    yeni_kod = re.sub(pattern, rep, kod)

    outdir = os.path.dirname(os.path.abspath(path))
    with open(path + ".yeni", "w", encoding='utf-8') as f:
        f.write(yeni_kod)
    with open(os.path.join(outdir, "tr_yeni.json"), "w", encoding='utf-8') as f:
        json.dump(bulunan, f, ensure_ascii=False, indent=2)
    with open(os.path.join(outdir, "en_yeni.json"), "w", encoding='utf-8') as f:
        json.dump({k: "" for k in bulunan}, f, ensure_ascii=False, indent=2)

    print(f"OK — {len(bulunan)} metin bulundu ve degistirildi")
    print(f"  {os.path.basename(path)}.yeni  -> degistirilmis kod")
    print(f"  tr_yeni.json  -> Turkce metinler")
    print(f"  en_yeni.json  -> Ingilizce (bos)")
    print(f"\nBulunan metinler:")
    for k, v in bulunan.items():
        print(f"  {k}: {v}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Kullanim: python i18n_extract.py <dart_dosyasi>"); sys.exit(1)
    main(sys.argv[1])