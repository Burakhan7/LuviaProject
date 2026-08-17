// Features/Outfits/RuleBasedRecommender.cs
using Luvia.Application.DTOs;
using Luvia.Application.Interfaces;
using Luvia.Domain.Entities;
using Luvia.Domain.Enums;
using Luvia.Domain.Extensions;

namespace Luvia.Application.Features.Outfits;

public record OutfitResult(
    IReadOnlyList<Outfit> Outfits,
    string? MissingMessage = null
);

public class RuleBasedRecommender : IOutfitRecommender
{
    public OutfitResult Recommend(
        IReadOnlyList<WardrobeItem> wardrobe,
        OutfitContext context,
        int maxResults = 5,
        int offset = 0)
    {
        wardrobe = wardrobe.Where(i => i.IsAvailable).ToList();

        // ═══ EKSİK KONTROLÜ: seçilen renk/stilde parça yoksa kombin önerme, uyar ═══
        if (context.PreferredColor is not null)
        {
            bool hasColor = wardrobe.Any(i => i.Color == context.PreferredColor.Value);
            if (!hasColor)
            {
                return new OutfitResult(
                    new List<Outfit>(),
                    $"Dolabında {context.PreferredColor} renginde kıyafet yok. Bu renkte bir parça ekleyince öneri sunabilirim."
                );
            }
        }

        if (context.PreferredStyle is not null)
        {
            bool hasStyle = wardrobe.Any(i => i.Style == context.PreferredStyle.Value);
            if (!hasStyle)
            {
                return new OutfitResult(
                    new List<Outfit>(),
                    $"Dolabında {context.PreferredStyle} tarzında kıyafet yok. Bu tarzda bir parça ekleyince öneri sunabilirim."
                );
            }
        }

        // ── AŞAMA 1: Slot'lara ayır ──
        var tops = wardrobe.Where(i => i.Kind == ItemKind.Clothing && IsTop(i.Category)).ToList();
        var bottoms = wardrobe.Where(i => i.Kind == ItemKind.Clothing && IsBottom(i.Category)).ToList();
        var dresses = wardrobe.Where(i => i.Category == Category.Dress).ToList();
        var shoes = wardrobe.Where(i => i.Kind == ItemKind.Shoes).ToList();

        var candidates = new List<Outfit>();

        // ── Aday kombinler üret (üst + alt + ayakkabı) ──
        foreach (var top in tops)
            foreach (var bottom in bottoms)
                foreach (var shoe in shoes)
                {
                    var items = new List<WardrobeItem> { top, bottom, shoe };

                    if (!PassesHardConstraints(items, context))
                        continue;

                    var (score, reasons) = ScoreOutfit(items, context);
                    candidates.Add(new Outfit { Items = items, Score = score, Reasons = reasons });
                }

        // ── Elbise bazlı kombinler (elbise + ayakkabı) ──
        foreach (var dress in dresses)
            foreach (var shoe in shoes)
            {
                var items = new List<WardrobeItem> { dress, shoe };

                if (!PassesHardConstraints(items, context))
                    continue;

                var (score, reasons) = ScoreOutfit(items, context);
                candidates.Add(new Outfit { Items = items, Score = score, Reasons = reasons });
            }

        var selected = SelectDiverse(candidates, maxResults);
        var page = selected.Skip(offset).Take(maxResults).ToList();
        return new OutfitResult(page);
    }

    // ── GÜNÜN KOMBİNİ: determinist + son günlerle çeşitlilik ──
    public Outfit? RecommendDaily(
        IReadOnlyList<WardrobeItem> wardrobe,
        OutfitContext context,
        DateOnly date)
    {
        // Tüm geçerli adayları üret + skorla (Recommend ile aynı mantık)
        var candidates = BuildCandidates(wardrobe, context);
        if (candidates.Count == 0) return null;

        // Skora göre sırala (en iyi başta)
        candidates = candidates.OrderByDescending(o => o.Score).ToList();

        // Dinamik geriye bakış: aday sayısına göre kaç güne bakılacağı
        int lookback;
        if (candidates.Count < 10) lookback = 1;
        else if (candidates.Count < 30) lookback = 2;
        else lookback = 3;

        // Geçmiş günlerin kombinlerini (aynı yöntemle) yeniden hesapla
        var pastItemIds = new HashSet<Guid>();
        var pastCombos = new List<List<Guid>>();
        for (int d = 1; d <= lookback; d++)
        {
            var pastDate = date.AddDays(-d);
            var pastCombo = PickForDate(candidates, pastDate);
            if (pastCombo != null)
            {
                pastCombos.Add(pastCombo.Items.Select(i => i.Id).ToList());
            }
        }

        // Bugünün adaylarını, geçmiş günlerle ortaklığa göre önceliklendir
        // Öncelik: her geçmiş günle ≤1 ortak (mümkünse 0)
        Outfit? best = null;
        int bestMaxShared = int.MaxValue;

        // Determinist tarama sırası: bugünün seed'ine göre karıştır ama sıralı
        var ordered = OrderBySeed(candidates, date);

        foreach (var candidate in ordered)
        {
            var ids = candidate.Items.Select(i => i.Id).ToList();
            // Bu adayın, geçmiş günlerin herhangi biriyle en çok kaç ortak item'ı var
            int maxShared = 0;
            foreach (var combo in pastCombos)
            {
                int shared = ids.Count(id => combo.Contains(id));
                if (shared > maxShared) maxShared = shared;
            }

            // İdeal: 0 ortak. Kabul: ≤1 ortak. En az benzeyeni sakla (fallback).
            if (maxShared == 0)
            {
                return candidate; // mükemmel — hiç ortak yok, direkt seç
            }
            if (maxShared < bestMaxShared)
            {
                bestMaxShared = maxShared;
                best = candidate;
            }
        }

        // 0 ortak bulunamadıysa, en az benzeyen (mümkünse ≤1) döner
        return best ?? candidates.First();
    }

    // Belirli bir tarih için determinist kombin seç (geçmiş gün hesabı için)
    private Outfit? PickForDate(List<Outfit> candidates, DateOnly date)
    {
        var ordered = OrderBySeed(candidates, date);
        return ordered.FirstOrDefault();
    }

    // Tarihi seed olarak kullanıp adayları determinist sırala
    // (skoru yüksekleri öne alır ama güne göre döndürür)
    private static List<Outfit> OrderBySeed(List<Outfit> candidates, DateOnly date)
    {
        int seed = date.DayNumber;
        // Yüksek skorluları koru ama seed'e göre deterministik döndür:
        // her adaya (skor + seed'e bağlı sabit bir kayma) ver, ona göre sırala
        return candidates
            .OrderByDescending(o => o.Score - 0.15 * (StableHash(o, seed) % 5) / 5.0)
            .ToList();
    }

    // Bir kombin + seed için sabit (deterministik) bir sayı üretir
    private static int StableHash(Outfit outfit, int seed)
    {
        int h = seed;
        foreach (var item in outfit.Items.OrderBy(i => i.Id))
        {
            h = h * 31 + item.Id.GetHashCode();
        }
        return Math.Abs(h);
    }

    // Aday üretimi — Recommend'ten çıkarıldı, tekrar kullanım için
    private List<Outfit> BuildCandidates(
        IReadOnlyList<WardrobeItem> wardrobe, OutfitContext context)
    {
        var available = wardrobe.Where(i => i.IsAvailable).ToList();
        var tops = available.Where(i => i.Kind == ItemKind.Clothing && IsTop(i.Category)).ToList();
        var bottoms = available.Where(i => i.Kind == ItemKind.Clothing && IsBottom(i.Category)).ToList();
        var dresses = available.Where(i => i.Category == Category.Dress).ToList();
        var shoes = available.Where(i => i.Kind == ItemKind.Shoes).ToList();

        var candidates = new List<Outfit>();

        foreach (var top in tops)
            foreach (var bottom in bottoms)
                foreach (var shoe in shoes)
                {
                    var items = new List<WardrobeItem> { top, bottom, shoe };
                    if (!PassesHardConstraints(items, context)) continue;
                    var (score, reasons) = ScoreOutfit(items, context);
                    candidates.Add(new Outfit { Items = items, Score = score, Reasons = reasons });
                }

        foreach (var dress in dresses)
            foreach (var shoe in shoes)
            {
                var items = new List<WardrobeItem> { dress, shoe };
                if (!PassesHardConstraints(items, context)) continue;
                var (score, reasons) = ScoreOutfit(items, context);
                candidates.Add(new Outfit { Items = items, Score = score, Reasons = reasons });
            }

        return candidates;
    }

    // Çeşitlilik cezalı seçim: her adımda, seçilenlere en çok benzeyeni cezalandırıp
    // en yüksek "düzeltilmiş puana" sahip kombini seçer.
    private static IReadOnlyList<Outfit> SelectDiverse(List<Outfit> candidates, int maxResults)
    {
        const double penaltyPerSharedItem = 0.15;   // ortak parça başına ceza

        var selected = new List<Outfit>();
        var pool = candidates.ToList();

        while (selected.Count < maxResults && pool.Count > 0)
        {
            Outfit? best = null;
            double bestAdjusted = double.NegativeInfinity;

            foreach (var candidate in pool)
            {
                int shared = MaxSharedItems(candidate, selected);
                double adjusted = candidate.Score - penaltyPerSharedItem * shared;

                if (adjusted > bestAdjusted)
                {
                    bestAdjusted = adjusted;
                    best = candidate;
                }
            }

            if (best is null) break;
            selected.Add(best);
            pool.Remove(best);
        }

        return selected;
    }

    // Bir adayın, seçilenler arasında EN ÇOK benzediği kombinle kaç ortak parçası var.
    private static int MaxSharedItems(Outfit candidate, List<Outfit> selected)
    {
        int max = 0;
        foreach (var s in selected)
        {
            int shared = candidate.Items.Count(ci => s.Items.Any(si => si.Id == ci.Id));
            if (shared > max) max = shared;
        }
        return max;
    }

    // ── Yardımcı: kategori hangi slota ait ──
    private static bool IsTop(Category c) => c is
        Category.TShirt or Category.Shirt or Category.Sweater or
        Category.Hoodie or Category.Cardigan or Category.Jacket or
        Category.Coat or Category.Blazer;

    private static bool IsBottom(Category c) => c is
        Category.Jeans or Category.Pants or Category.Shorts or
        Category.Skirt or Category.Sweatpants;

    // ── KATI KISITLAR: geçersiz kombini ele (true = geçerli) ──
    private static bool PassesHardConstraints(List<WardrobeItem> items, OutfitContext ctx)
    {
        return SeasonCompatible(items, ctx.Season)
            && FormalityCoherent(items);
    }

    private static bool SeasonCompatible(List<WardrobeItem> items, Season target)
    {
        foreach (var item in items)
        {
            if (item.Season is null) continue;
            if (item.Season == Season.MidSeason) continue;
            if (item.Season != target) return false;
        }
        return true;
    }

    private static bool FormalityCoherent(List<WardrobeItem> items)
    {
        var levels = items
            .Where(i => i.Formality is not null)
            .Select(i => (int)i.Formality!.Value)
            .ToList();

        if (levels.Count < 2) return true;
        return (levels.Max() - levels.Min()) <= 1;
    }

    // ── AŞAMA 2: PUANLAMA (0.0 - 1.0 skor + açıklamalar) ──
    private static (double score, List<string> reasons) ScoreOutfit(
    List<WardrobeItem> items, OutfitContext ctx)
    {
        var reasons = new List<string>();

        double color = ScoreColor(items, reasons);
        double formality = ScoreFormality(items, reasons);
        double pattern = ScorePattern(items, reasons);
        double style = ScoreStyle(items, reasons);

        // ── A) Temel boyutlar (her zaman sayılır) ve ağırlıkları ──
        // color, formality, pattern, style
        double baseScore = color * 0.42 + formality * 0.24 + pattern * 0.18 + style * 0.16;
        // (0.42 + 0.24 + 0.18 + 0.16 = 1.0 — temel boyutlar kendi içinde tam)

        // ── A) Tercih boyutları: SADECE kullanıcı seçtiyse skora kat ──
        // Seçilmediyse toplama hiç girmez (bedava 1.0 puanı yok)
        double total = baseScore;

        if (ctx.PreferredColor is not null)
        {
            double colorPref = ScoreColorPreference(items, ctx.PreferredColor, reasons);
            // Tercih uyumu, temel skoru ±%15 kaydırır (çarpan olarak)
            total *= (0.85 + 0.15 * colorPref);
        }

        if (ctx.PreferredStyle is not null)
        {
            double stylePref = ScoreStylePreference(items, ctx.PreferredStyle, reasons);
            total *= (0.85 + 0.15 * stylePref);
        }

        // ── B) Renk çarpımsal cezası ──
        // Renk kombinin temeli. Çok kötüyse (çakışan / 3+ canlı renk) tüm skoru aşağı çek.
        if (color < 0.5)
        {
            // color 0.2 ise → 0.2/0.5 = 0.4 çarpanı → skor ciddi düşer
            double colorPenalty = color / 0.5;
            total *= colorPenalty;
            reasons.Add("Renk uyumsuzluğu genel puanı belirgin düşürdü");
        }

        // Skoru 0-1 aralığında tut
        total = Math.Clamp(total, 0.0, 1.0);

        return (total, reasons);
    }
    private static double ScoreColor(List<WardrobeItem> items, List<string> reasons)
    {
        // Nötr olmayan (canlı) renkleri ayır
        var accents = items.Where(i => !i.Color.IsNeutral()).Select(i => i.Color).ToList();
        int accentCount = accents.Count;

        // Hepsi nötr → en güvenli uyum
        if (accentCount == 0)
        {
            reasons.Add("Tamamen nötr tonlar — şık ve güvenli uyum");
            return 1.0;
        }

        // Tek aksan renk + nötr zemin → dengeli, klasik
        if (accentCount == 1)
        {
            reasons.Add("Nötr zemin üzerine tek aksan renk — dengeli ve modern");
            return 0.95;
        }

        // İki aksan renk → renk çemberi ilişkisine bak (analog / komplementer / çakışan)
        if (accentCount == 2)
        {
            double hueDiff = ColorLab.HueAngleDiff(accents[0], accents[1]);

            if (hueDiff <= 40)
            {
                reasons.Add($"{accents[0]} ve {accents[1]} — analog renkler, yumuşak ve uyumlu");
                return 0.9;
            }
            if (hueDiff >= 140)
            {
                reasons.Add($"{accents[0]} ve {accents[1]} — komplementer kontrast, çarpıcı ama kasıtlı");
                return 0.75;
            }
            // Orta açı → çakışma riski
            reasons.Add($"{accents[0]} ve {accents[1]} — renkler biraz çakışıyor, dikkatli kombin");
            return 0.45;
        }

        // Üç+ aksan renk → "3 renk kuralı" ihlali (nötrler hariç 2'yi geçmemeli)
        reasons.Add("Çok sayıda canlı renk — sadeleştirmek daha şık durur");
        return 0.25;
    }

    private static double ScoreFormality(List<WardrobeItem> items, List<string> reasons)
    {
        var levels = items
            .Where(i => i.Formality is not null)
            .Select(i => (int)i.Formality!.Value)
            .ToList();

        if (levels.Count < 2) return 0.7;

        int spread = levels.Max() - levels.Min();

        if (spread == 0)
        {
            reasons.Add("Formalite tam hizalı — bütünlüklü duruş");
            return 1.0;
        }
        if (spread == 1)
        {
            // Araştırma: 1 kademe fark kasıtlı, modern bir kontrast (blazer + sneaker gibi)
            reasons.Add("Hafif formalite kontrastı — modern ve dengeli");
            return 0.85;
        }
        if (spread == 2)
        {
            reasons.Add("Formalite farkı biraz yüksek — dikkatli taşınmalı");
            return 0.45;
        }
        // 3+ kademe: örneğin spor ayakkabı + çok resmi parça — dengesiz
        reasons.Add("Formalite uçları çok açık — dengesiz durabilir");
        return 0.25;
    }

    private static double ScoreStyle(List<WardrobeItem> items, List<string> reasons)
    {
        var styles = items.Where(i => i.Style is not null)
                          .Select(i => i.Style!.Value)
                          .ToList();

        if (styles.Count < 2) return 0.7;

        int dominant = styles.GroupBy(s => s).Max(g => g.Count());
        double ratio = (double)dominant / styles.Count;

        if (ratio == 1.0)
        {
            reasons.Add("Tek tutarlı stil — net bir karakter");
            return 1.0;
        }
        if (ratio >= 0.66)
        {
            reasons.Add("Baskın bir stil var, uyumlu");
            return 0.8;
        }
        if (ratio >= 0.5)
        {
            // Yarı yarıya — kasıtlı karışım olabilir, orta
            reasons.Add("İki stil dengeli karışmış — bilinçli bir tercih");
            return 0.6;
        }
        reasons.Add("Stiller dağınık — bir yöne çekmek daha iyi");
        return 0.4;
    }

    private static double ScorePattern(List<WardrobeItem> items, List<string> reasons)
    {
        // Desenli parçaları say (Solid = düz, gerisi desenli)
        var patterned = items
            .Where(i => i.Pattern is not null && i.Pattern != Domain.Enums.Pattern.Solid)
            .ToList();

        int patternCount = patterned.Count;

        if (patternCount == 0)
        {
            reasons.Add("Tüm parçalar düz — temiz ve güvenli");
            return 0.85;
        }
        if (patternCount == 1)
        {
            reasons.Add("Tek desenli parça, gerisi düz — ideal denge");
            return 1.0;
        }
        if (patternCount == 2)
        {
            // İki desen — araştırma: ancak dikkatli/ortak renkle tolere edilir
            reasons.Add("İki desenli parça — cesur, dikkatli kombinlenmeli");
            return 0.5;
        }
        // Üç+ desen — dağınık
        reasons.Add("Çok fazla desen — sadeleştirmek daha şık");
        return 0.3;
    }

    // Renk tercihi (Yorum B): 1-2 parça o renk = yüksek, hepsi = ceza, hiç = çok düşük
    private static double ScoreColorPreference(
        List<WardrobeItem> items, ColorName? preferred, List<string> reasons)
    {
        if (preferred is null) return 1.0;   // tercih yok → nötr

        int matchCount = items.Count(i => i.Color == preferred.Value);
        int total = items.Count;

        if (matchCount == 0)
        {
            reasons.Add($"Seçilen renk ({preferred}) kombinde yok");
            return 0.1;
        }
        if (matchCount == total)
        {
            reasons.Add($"Tamamen {preferred} — tek düze");
            return 0.4;
        }
        reasons.Add($"{preferred} ön planda, dengeli");
        return 1.0;
    }

    // Stil tercihi: baskın olsun ama katı değil
    private static double ScoreStylePreference(
        List<WardrobeItem> items, Style? preferred, List<string> reasons)
    {
        if (preferred is null) return 1.0;   // tercih yok → nötr

        var styled = items.Where(i => i.Style is not null).ToList();
        if (styled.Count == 0) return 0.5;

        int matchCount = styled.Count(i => i.Style!.Value == preferred.Value);
        double ratio = (double)matchCount / styled.Count;

        if (ratio == 0)
        {
            reasons.Add($"Seçilen stil ({preferred}) kombinde yok");
            return 0.1;
        }
        if (ratio >= 0.5)
        {
            reasons.Add($"{preferred} stili baskın");
            return 1.0;
        }
        reasons.Add($"{preferred} stili var ama zayıf");
        return 0.6;
    }

    // Tek kombini değerlendir — mevcut ScoreOutfit mantığını kullanır (tutarlılık)
    public (double score, IReadOnlyList<string> reasons) Evaluate(
        IReadOnlyList<WardrobeItem> items,
        OutfitContext context)
    {
        var list = items.ToList();
        var (score, reasons) = ScoreOutfit(list, context);
        return (score, reasons);
    }
}