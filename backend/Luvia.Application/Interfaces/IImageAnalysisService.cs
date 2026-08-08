// Interfaces/IImageAnalysisService.cs
using Luvia.Application.DTOs;

namespace Luvia.Application.Interfaces;

/// <summary>
/// Bir görüntü URL'ini analiz edip attribute'lara çeviren servis.
/// Implementasyonu Infrastructure'da: önce MockAnalysisService, sonra PythonCvAnalysisService.
/// </summary>
public interface IImageAnalysisService
{
    Task<ImageAnalysisResult> AnalyzeAsync(string imageUrl, CancellationToken ct = default);
    Task<List<ImageAnalysisResult>> AnalyzeFullbodyAsync(string imageUrl, CancellationToken ct = default);
}