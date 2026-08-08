// Services/PythonCvAnalysisService.cs
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Luvia.Application.DTOs;
using Luvia.Application.Interfaces;

namespace Luvia.Infrastructure.Services;

/// <summary>
/// Python CV servisine (FastAPI /analyze) HTTP isteði atýp sonucu ImageAnalysisResult'a çevirir.
/// Mock'un gerçek karþýlýðý — interface ayný, üst katmanlar farký bilmez.
/// </summary>
public class PythonCvAnalysisService : IImageAnalysisService
{
    private readonly HttpClient _http;

    // Field: sýnýf üyesi, metotlarýn DIÞINDA. Python string enum ("TShirt") -> C# enum parse için.
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        Converters = { new JsonStringEnumConverter() },
        PropertyNameCaseInsensitive = true
    };

    public PythonCvAnalysisService(HttpClient http) => _http = http;

    public async Task<ImageAnalysisResult> AnalyzeAsync(string imageUrl, CancellationToken ct = default)
    {
        // Python'a { "imageUrl": "..." } gönder
        var response = await _http.PostAsJsonAsync("/analyze", new { imageUrl }, ct);
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync(ct);
            throw new InvalidOperationException(
                $"CV servisi {(int)response.StatusCode} döndü: {errorBody}");
        }

        // Dönen JSON zaten ImageAnalysisResult ile birebir eþleþiyor (contract-first!)
        var result = await response.Content.ReadFromJsonAsync<ImageAnalysisResult>(JsonOptions, ct);

        if (result is null)
            throw new InvalidOperationException("CV servisi boþ yanýt döndü.");

        return result;
    }
    public async Task<List<ImageAnalysisResult>> AnalyzeFullbodyAsync(string imageUrl, CancellationToken ct = default)
    {
        var response = await _http.PostAsJsonAsync("/analyze-fullbody", new { imageUrl }, ct);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync(ct);
            throw new InvalidOperationException(
                $"CV servisi {(int)response.StatusCode} döndü: {errorBody}");
        }

        var wrapper = await response.Content.ReadFromJsonAsync<FullbodyWrapper>(JsonOptions, ct);
        return wrapper?.Items ?? new List<ImageAnalysisResult>();
    }

    // Python'un {"items": [...]} yanýtýný karþýlar
    private class FullbodyWrapper
    {
        public List<ImageAnalysisResult> Items { get; set; } = new();
    }
    public async Task DeleteImageAsync(string imageUrl, CancellationToken ct = default)
    {
        try
        {
            await _http.PostAsJsonAsync("/delete-image", new { imageUrl }, ct);
            // best-effort: hata olsa da item silme devam etsin
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Görsel silme baþarýsýz (yok sayýldý): {ex.Message}");
        }
    }
}