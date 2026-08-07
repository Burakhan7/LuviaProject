// Persistence/Configurations/WardrobeItemConfiguration.cs
using Luvia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Luvia.Infrastructure.Persistence.Configurations;

public class WardrobeItemConfiguration : IEntityTypeConfiguration<WardrobeItem>
{
	public void Configure(EntityTypeBuilder<WardrobeItem> b)
	{
		b.ToTable("WardrobeItems");
		b.HasKey(x => x.Id);

		b.Property(x => x.UserId).IsRequired().HasMaxLength(128);
		b.Property(x => x.OriginalImageUrl).IsRequired().HasMaxLength(1000);
		b.Property(x => x.ProcessedImageUrl).HasMaxLength(1000);

		// ── Enum'ları string olarak sakla (int değil) ──
		// Sebep: DB'de "TShirt", "Blue" okunur; enum'a yeni değer eklerken
		// sıra kaymasından etkilenmez. Okunabilirlik + dayanıklılık.
		b.Property(x => x.Kind).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.Category).HasConversion<string>().HasMaxLength(30);
		b.Property(x => x.Color).HasConversion<string>().HasMaxLength(20);

		b.Property(x => x.Style).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.Formality).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.Season).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.Pattern).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.Material).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.Fit).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.JewelryType).HasConversion<string>().HasMaxLength(20);
		b.Property(x => x.JewelryMaterial).HasConversion<string>().HasMaxLength(20);

		// Sık sorgulanacak alanlara index (kullanıcının gardırobunu çekmek)
		b.HasIndex(x => x.UserId);
	}
}