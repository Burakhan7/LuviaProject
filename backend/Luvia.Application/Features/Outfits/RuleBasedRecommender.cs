// Features/Outfits/RuleBasedRecommender.cs
using Luvia.Application.DTOs;
using Luvia.Application.Interfaces;
using Luvia.Domain.Entities;
using Luvia.Domain.Enums;
using Luvia.Domain.Extensions;

namespace Luvia.Application.Features.Outfits;

public class RuleBasedRecommender : IOutfitRecommender
{
    public IReadOnlyList<Outfit> Recommend(
        IReadOnlyList<WardrobeItem> wardrobe,
        OutfitContext context,
        int maxResults = 5)
    {
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

                    // AŞAMA 1: katı kısıt — geçmezse atla
                    if (!PassesHardConstraints(items, context))
                        continue;

                    // AŞAMA 2: puanla + açıklama üret
                    var (score, reasons) = ScoreOutfit(items);
                    candidates.Add(new Outfit { Items = items, Score = score, Reasons = reasons });
                }

        // ── Elbise bazlı kombinler (elbise + ayakkabı) ──
        foreach (var dress in dresses)
            foreach (var shoe in shoes)
            {
                var items = new List<WardrobeItem> { dress, shoe };

                if (!PassesHardConstraints(items, context))
                    continue;

                var (score, reasons) = ScoreOutfit(items);
                candidates.Add(new Outfit { Items = items, Score = score, Reasons = reasons });
            }

        return candidates
            .OrderByDescending(o => o.Score)
            .Take(maxResults)
            .ToList();
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

    private static (double score, List<string> reasons) ScoreOutfit(List<WardrobeItem> items)
    {
        var reasons = new List<string>();

        double color = ScoreColor(items, reasons);
        double formality = ScoreFormality(items, reasons);
        double style = ScoreStyle(items, reasons);

        double total = color * 0.5 + formality * 0.3 + style * 0.2;
        return (total, reasons);
    }

    private static double ScoreColor(List<WardrobeItem> items, List<string> reasons)
    {
        int accentCount = items.Count(i => !i.Color.IsNeutral());

        if (accentCount == 0) { reasons.Add("Tamamen nötr renkler — güvenli uyum"); return 1.0; }
        if (accentCount == 1) { reasons.Add("Nötr zemin + tek aksan renk — dengeli"); return 0.9; }
        if (accentCount == 2) { reasons.Add("İki canlı renk — dikkatli kombin"); return 0.5; }
        reasons.Add("Çok sayıda çarpışan renk");
        return 0.2;
    }

    private static double ScoreFormality(List<WardrobeItem> items, List<string> reasons)
    {
        var levels = items
            .Where(i => i.Formality is not null)
            .Select(i => (int)i.Formality!.Value)
            .ToList();

        if (levels.Count < 2) return 0.7;

        int spread = levels.Max() - levels.Min();
        if (spread == 0) { reasons.Add("Formallik tam hizalı"); return 1.0; }
        if (spread == 1) { reasons.Add("Formallik uyumlu"); return 0.8; }
        return 0.4;
    }

    private static double ScoreStyle(List<WardrobeItem> items, List<string> reasons)
    {
        var styles = items.Where(i => i.Style is not null)
                          .Select(i => i.Style!.Value)
                          .ToList();

        if (styles.Count < 2) return 0.7;

        int dominant = styles.GroupBy(s => s).Max(g => g.Count());
        double ratio = (double)dominant / styles.Count;

        if (ratio == 1.0) { reasons.Add("Tek tutarlı stil"); return 1.0; }
        if (ratio >= 0.66) { reasons.Add("Baskın stil uyumu"); return 0.75; }
        reasons.Add("Karışık stiller");
        return 0.4;
    }
}