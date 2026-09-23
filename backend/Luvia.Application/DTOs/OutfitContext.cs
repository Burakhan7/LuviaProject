// DTOs/OutfitContext.cs
using Luvia.Domain.Enums;

namespace Luvia.Application.DTOs;

/// <summary>
/// Kombin önerisinin baðlamý: hangi mevsim, hangi formallik hedefi.
/// Motor bu baðlama göre filtreler ve puanlar.
/// </summary>
public record OutfitContext(
    Season Season,
    Formality TargetFormality,
    ColorName? PreferredColor = null,   
    Style? PreferredStyle = null,
        double? MinTemp = null,   // çýkýþ-sonrasý en düþük sýcaklýk (°C)
    double? MaxTemp = null    // çýkýþ-sonrasý en yüksek sýcaklýk (°C)
);