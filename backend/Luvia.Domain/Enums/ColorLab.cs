// Enums/ColorLab.cs  (yeni dosya — renk → LAB sözlüğü + hesaplamalar)
namespace Luvia.Domain.Enums;

public static class ColorLab
{
    // Her rengin temsili LAB değeri (L, a, b)
    private static readonly Dictionary<ColorName, (double L, double A, double B)> _lab = new()
    {
        [ColorName.Black] = (0, 0, 0),
        [ColorName.White] = (100, 0, 0),
        [ColorName.Gray] = (54, 0, 0),
        [ColorName.Red] = (53, 80, 67),
        [ColorName.Burgundy] = (28, 45, 20),
        [ColorName.Orange] = (66, 45, 74),
        [ColorName.Yellow] = (89, -6, 90),
        [ColorName.Green] = (46, -51, 50),
        [ColorName.Khaki] = (62, -6, 38),
        [ColorName.Blue] = (45, 20, -60),
        [ColorName.Navy] = (20, 8, -35),
        [ColorName.Turquoise] = (72, -40, -5),
        [ColorName.Purple] = (35, 45, -40),
        [ColorName.Pink] = (75, 30, 0),
        [ColorName.Brown] = (37, 25, 40),
        [ColorName.Beige] = (85, 3, 18),
        [ColorName.Cream] = (95, 0, 12),
    };

    public static (double L, double A, double B) Of(ColorName c) => _lab[c];

    // İki renk arasındaki "hue açısı farkı" (0-180°) — renk çemberi ilişkisi
    // a-b düzleminde açı hesaplar (LAB'da hue = atan2(b, a))
    public static double HueAngleDiff(ColorName c1, ColorName c2)
    {
        var (_, a1, b1) = _lab[c1];
        var (_, a2, b2) = _lab[c2];

        double h1 = Math.Atan2(b1, a1) * 180 / Math.PI;
        double h2 = Math.Atan2(b2, a2) * 180 / Math.PI;

        double diff = Math.Abs(h1 - h2);
        if (diff > 180) diff = 360 - diff;
        return diff;
    }

    // Renk ne kadar "canlı/doygun" (chroma). Düşük = nötre yakın, gri.
    public static double Chroma(ColorName c)
    {
        var (_, a, b) = _lab[c];
        return Math.Sqrt(a * a + b * b);
    }
}