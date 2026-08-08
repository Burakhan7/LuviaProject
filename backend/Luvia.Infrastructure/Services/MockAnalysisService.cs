// Services/MockAnalysisService.cs
using Luvia.Application.DTOs;
using Luvia.Application.Interfaces;
using Luvia.Domain.Enums;

namespace Luvia.Infrastructure.Services;

public class MockAnalysisService : IImageAnalysisService
{
    public Task<ImageAnalysisResult> AnalyzeAsync(string imageUrl, CancellationToken ct = default)
    {
        var url = imageUrl.ToLowerInvariant();

        // URL'deki anahtar kelimeye göre farklý sahte item üret (test çeþitliliði için)
        ImageAnalysisResult result = url switch
        {
            _ when url.Contains("dress") => Make(Category.Dress, ColorName.Red, Style.Classic, Formality.SmartCasual, Season.Summer, Fabric.Cotton, null),
            _ when url.Contains("jeans") => Make(Category.Jeans, ColorName.Navy, Style.Casual, Formality.Casual, Season.MidSeason, Fabric.Denim, Fit.Regular),
            _ when url.Contains("pants") => Make(Category.Pants, ColorName.Beige, Style.Classic, Formality.SmartCasual, Season.MidSeason, Fabric.Cotton, Fit.Slim),
            _ when url.Contains("sneaker") => Make(Category.Sneakers, ColorName.White, Style.Sporty, Formality.Casual, Season.MidSeason, null, null),
            _ when url.Contains("boots") => Make(Category.Boots, ColorName.Black, Style.Classic, Formality.SmartCasual, Season.Winter, Fabric.Leather, null),
            _ when url.Contains("shirt") => Make(Category.Shirt, ColorName.White, Style.Classic, Formality.SmartCasual, Season.MidSeason, Fabric.Cotton, Fit.Slim),
            _ => Make(Category.TShirt, ColorName.Blue, Style.Casual, Formality.Casual, Season.Summer, Fabric.Cotton, Fit.Regular)
        };

        result.ProcessedImageUrl = imageUrl + "?processed=true";
        return Task.FromResult(result);
    }

    private static ImageAnalysisResult Make(
        Category cat, ColorName color, Style style, Formality formality,
        Season season, Fabric? material, Fit? fit)
        => new()
        {
            Category = cat,
            Color = color,
            Style = style,
            Formality = formality,
            Season = season,
            Pattern = Pattern.Solid,
            Material = material,
            Fit = fit,
            LowConfidenceFields = new()
        };
    public async Task<List<ImageAnalysisResult>> AnalyzeFullbodyAsync(string imageUrl, CancellationToken ct = default)
    {
        var single = await AnalyzeAsync(imageUrl, ct);
        return new List<ImageAnalysisResult> { single };
    }
    public Task DeleteImageAsync(string imageUrl, CancellationToken ct = default) => Task.CompletedTask;
}