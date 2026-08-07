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
        response.EnsureSuccessStatusCode();

        // Dönen JSON zaten ImageAnalysisResult ile birebir eþleþiyor (contract-first!)
        var result = await response.Content.ReadFromJsonAsync<ImageAnalysisResult>(JsonOptions, ct);

        if (result is null)
            throw new InvalidOperationException("CV servisi boþ yanýt döndü.");

        return result;
    }
}