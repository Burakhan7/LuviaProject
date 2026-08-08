// Features/Wardrobe/AddWardrobeItemHandler.cs
using Luvia.Application.DTOs;
using Luvia.Application.Interfaces;
using Luvia.Domain.Entities;

namespace Luvia.Application.Features.Wardrobe;

/// <summary>
/// Bir fotoğraf URL'inden yeni gardırop item'ı oluşturur:
/// CV analizini çağırır → item'ı doğurur → attribute'ları işler → kaydeder.
/// </summary>
public class AddWardrobeItemHandler
{
    private readonly IImageAnalysisService _analysis;
    private readonly IWardrobeItemRepository _repository;

    public AddWardrobeItemHandler(
        IImageAnalysisService analysis,
        IWardrobeItemRepository repository)
    {
        _analysis = analysis;
        _repository = repository;
    }

    public async Task<WardrobeItem> HandleAsync(AddItemRequest request, CancellationToken ct = default)
    {
        // 1. CV servisi görüntüyü analiz eder (URL alır, attribute'lar döner)
        ImageAnalysisResult result = await _analysis.AnalyzeAsync(request.OriginalImageUrl, ct);

        // 2. Item'ı çekirdek bilgiyle doğur (Kind, Category'den türetilir)
        var item = WardrobeItem.Create(
            request.UserId,
            request.OriginalImageUrl,
            result.Category,
            result.Color);

        // 3. CV'nin bulduğu attribute'ları işle; kararsız alan varsa onaya düşür
        item.ApplyAnalysis(
            color: result.Color,
            processedImageUrl: result.ProcessedImageUrl,
            isLayered: result.IsLayered,
            style: result.Style,
            formality: result.Formality,
            season: result.Season,
            pattern: result.Pattern,
            material: result.Material,
            fit: result.Fit,
            jewelryType: result.JewelryType,
            jewelryMaterial: result.JewelryMaterial,
            needsReview: result.LowConfidenceFields.Count > 0);

        // 4. Kaydet
        await _repository.AddAsync(item, ct);
        await _repository.SaveChangesAsync(ct);

        return item;
    }
}