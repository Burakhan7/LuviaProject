// DTOs/Outfit.cs
using Luvia.Domain.Entities;

namespace Luvia.Application.DTOs;

/// <summary>
/// Önerilen tek bir kombin: parçalar + toplam uyum puaný + neden-açýklamasý.
/// </summary>
public class Outfit
{
    public List<WardrobeItem> Items { get; init; } = new();
    public double Score { get; init; }
    public List<string> Reasons { get; init; } = new();  // "Nötr renk uyumu", "Formallik tutarlý" gibi
}