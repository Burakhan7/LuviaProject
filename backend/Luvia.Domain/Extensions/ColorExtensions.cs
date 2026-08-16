// Extensions/ColorExtensions.cs
using Luvia.Domain.Enums;

namespace Luvia.Domain.Extensions;

public static class ColorExtensions
{
    // Nötr renkler her þeyle uyumludur; kombin mantýðýnýn temeli bu
    private static readonly HashSet<ColorName> Neutrals = new()
    {
        ColorName.Black, ColorName.White, ColorName.Gray,
        ColorName.Navy, ColorName.Beige, ColorName.Cream,
        ColorName.Khaki, ColorName.Brown
    };

    public static bool IsNeutral(this ColorName color) => Neutrals.Contains(color);
}