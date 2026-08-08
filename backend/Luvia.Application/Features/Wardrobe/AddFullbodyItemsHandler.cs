// Features/Wardrobe/AddFullbodyItemsHandler.cs
using Luvia.Application.DTOs;
using Luvia.Application.Interfaces;
using Luvia.Domain.Entities;

namespace Luvia.Application.Features.Wardrobe;

/// <summary>
/// Boydan fotoðraftan çýkan HER parçayý ayrý WardrobeItem olarak kaydeder.
/// </summary>
public class AddFullbodyItemsHandler
{
    private readonly IImageAnalysisService _analysis;
    private readonly IWardrobeItemRepository _repository;

    public AddFullbodyItemsHandler(IImageAnalysisService analysis, IWardrobeItemRepository repository)
    {
        _analysis = analysis;
        _repository = repository;
    }

    public async Task<List<WardrobeItem>> HandleAsync(AddItemRequest request, CancellationToken ct = default)
    {
        // Python'dan çoklu parça al
        var results = await _analysis.AnalyzeFullbodyAsync(request.OriginalImageUrl, ct);

        var items = new List<WardrobeItem>();
        foreach (var result in results)
        {
            var item = WardrobeItem.Create(
                request.UserId,
                request.OriginalImageUrl,       // hepsi ayný orijinal fotodan geldi
                result.Category,
                result.Color);

            item.ApplyAnalysis(
                color: result.Color,
                processedImageUrl: result.ProcessedImageUrl,   // her parçanýn kendi kesimi
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

            await _repository.AddAsync(item, ct);
            items.Add(item);
        }

        await _repository.SaveChangesAsync(ct);
        return items;
    }
}