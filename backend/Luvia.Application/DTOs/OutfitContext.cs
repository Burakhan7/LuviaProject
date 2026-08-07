// DTOs/OutfitContext.cs
using Luvia.Domain.Enums;

namespace Luvia.Application.DTOs;

/// <summary>
/// Kombin önerisinin baðlamý: hangi mevsim, hangi formallik hedefi.
/// Motor bu baðlama göre filtreler ve puanlar.
/// </summary>
public record OutfitContext(
    Season Season,
    Formality TargetFormality
);