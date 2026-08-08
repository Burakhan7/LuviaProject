// Entities/WardrobeItem.cs
using Luvia.Domain.Enums;
using Luvia.Domain.Extensions;

namespace Luvia.Domain.Entities;

public class WardrobeItem
{
    public Guid Id { get; private set; }
    public string UserId { get; private set; } = default!;

    // Görseller — foto Storage'da, burada sadece URL (backend ham foto taşımaz)
    public string OriginalImageUrl { get; private set; } = default!;
    public string? ProcessedImageUrl { get; private set; }

    // Her item'da olan çekirdek alanlar
    public ItemKind Kind { get; private set; }
    public Category Category { get; private set; }
    public ColorName Color { get; private set; }

    // Türe göre dolan attribute'lar (nullable — kind neyse o alanlar dolar)
    public Style? Style { get; private set; }
    public Formality? Formality { get; private set; }
    public Season? Season { get; private set; }
    public Pattern? Pattern { get; private set; }
    public Fabric? Material { get; private set; }
    public Fit? Fit { get; private set; }
    public JewelryType? JewelryType { get; private set; }
    public JewelryMaterial? JewelryMaterial { get; private set; }

    // CV bir attribute'ta kararsız kaldıysa (⚠) kullanıcı onayına düşsün
    public bool NeedsReview { get; private set; }

    public DateTime CreatedAt { get; private set; }

    // EF Core parametresiz ctor ister; dışarıya kapalı
    private WardrobeItem() { }

    /// <summary>
    /// Yeni bir gardırop item'ı oluşturur. Kind DAİMA Category'den türetilir,
    /// böylece "Sneakers ama Kind=Clothing" gibi tutarsız durum imkansızdır.
    /// </summary>
    public static WardrobeItem Create(
        string userId,
        string originalImageUrl,
        Category category,
        ColorName color)
    {
        if (string.IsNullOrWhiteSpace(userId))
            throw new ArgumentException("UserId boş olamaz.", nameof(userId));
        if (string.IsNullOrWhiteSpace(originalImageUrl))
            throw new ArgumentException("OriginalImageUrl boş olamaz.", nameof(originalImageUrl));

        return new WardrobeItem
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            OriginalImageUrl = originalImageUrl,
            Category = category,
            Kind = category.ToKind(),   // ← tutarlılık burada garanti altında
            Color = color,
            CreatedAt = DateTime.UtcNow
        };
    }
    /// <summary>
    /// CV analiz sonucunu item'a işler. Attribute'ları TÜRE göre süzer:
    /// clothing'e Fit yazar ama jewelry'ye yazmaz. Kind'a uymayan alanlar yok sayılır.
    /// </summary>
    public void ApplyAnalysis(
        ColorName color,
        string? processedImageUrl,
        bool isLayered = false,
        Style? style = null,
        Formality? formality = null,
        Season? season = null,
        Pattern? pattern = null,
        Fabric? material = null,
        Fit? fit = null,
        JewelryType? jewelryType = null,
        JewelryMaterial? jewelryMaterial = null,
        bool needsReview = false)
    {
        Color = color;
        ProcessedImageUrl = processedImageUrl;
        IsLayered = isLayered;

        // Ortak alanlar (renk hariç türlere göre değişir)
        switch (Kind)
        {
            case ItemKind.Clothing:
                Style = style;
                Formality = formality;
                Season = season;
                Pattern = pattern;
                Material = material;
                Fit = fit;
                break;

            case ItemKind.Shoes:
                Style = style;
                Season = season;
                Material = material;
                break;

            case ItemKind.Accessory:
                Style = style;
                Material = material;
                break;

            case ItemKind.Jewelry:
                JewelryType = jewelryType;
                JewelryMaterial = jewelryMaterial;
                Style = style;
                break;
        }

        NeedsReview = needsReview;
    }

    /// <summary>Kullanıcı belirsiz alanları onayladığında çağrılır.</summary>
    public void MarkReviewed() => NeedsReview = false;
    // CV: bu üst parça katmanlı algılandı mı? Kullanıcıya "iç parça da ekle" sinyali için.
    public bool IsLayered { get; private set; }
}