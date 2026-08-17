// Interfaces/IOutfitRecommender.cs
using Luvia.Application.DTOs;
using Luvia.Domain.Entities;
using Luvia.Application.Features.Outfits;
namespace Luvia.Application.Interfaces;

/// <summary>
/// Bir gardýroptan, verilen baðlama uygun kombinleri üretip puanlayan motor.
/// Saf iþ mantýðý — DB/HTTP/AI baðýmlýlýðý YOK. Deterministik, test edilebilir.
/// </summary>
public interface IOutfitRecommender
{
    OutfitResult Recommend(  
        IReadOnlyList<WardrobeItem> wardrobe,
        OutfitContext context,
        int maxResults = 5,
         int offset = 0

        );

    // Tek bir kombini (kullanýcýnýn seçtiði parçalar) deðerlendirir: skor + yorumlar
    (double score, IReadOnlyList<string> reasons) Evaluate(
        IReadOnlyList<WardrobeItem> items,
        OutfitContext context);

    // Günün kombini — determinist, son günlerle çeþitli
    Outfit? RecommendDaily(
        IReadOnlyList<WardrobeItem> wardrobe,
        OutfitContext context,
        DateOnly date);
}