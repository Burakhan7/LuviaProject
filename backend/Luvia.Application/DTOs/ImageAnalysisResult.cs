// DTOs/ImageAnalysisResult.cs
using Luvia.Domain.Enums;

namespace Luvia.Application.DTOs;

/// <summary>
/// CV servisinin tek bir kıyafet/parça için döndürdüğü analiz sonucu.
/// Tüm attribute'lar burada; entity bunları türe göre süzüp kendine işler.
/// </summary>
public class ImageAnalysisResult
{
    // Çekirdek (her item'da olur)
    public Category Category { get; set; }
    public ColorName Color { get; set; }

    // Arka planı silinmiş / işlenmiş görsel (Python Storage'a yazar, URL'ini döner)
    public string? ProcessedImageUrl { get; set; }

    // Türe göre dolabilecek attribute'lar (CV neyi bulduysa)
    public Style? Style { get; set; }
    public Formality? Formality { get; set; }
    public Season? Season { get; set; }
    public Pattern? Pattern { get; set; }
    public Fabric? Material { get; set; }
    public Fit? Fit { get; set; }
    public JewelryType? JewelryType { get; set; }
    public JewelryMaterial? JewelryMaterial { get; set; }

    // CV'nin kararsız kaldığı alanların adları (Python'daki ⚠ bayrağı).
    // Boş değilse item NeedsReview = true olur.
    public List<string> LowConfidenceFields { get; set; } = new();
}