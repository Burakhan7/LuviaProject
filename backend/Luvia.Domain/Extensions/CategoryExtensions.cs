// Extensions/CategoryExtensions.cs
using Luvia.Domain.Enums;

namespace Luvia.Domain.Extensions;

public static class CategoryExtensions
{
    private static readonly HashSet<Category> ShoeCategories = new()
    {
        Category.Sneakers, Category.Boots, Category.Heels, Category.Sandals
    };

    private static readonly HashSet<Category> JewelryCategories = new()
    {
        Category.Necklace, Category.Earrings, Category.Ring,
        Category.Bracelet, Category.Watch, Category.Brooch
    };

    private static readonly HashSet<Category> AccessoryCategories = new()
    {
        Category.Hat, Category.Bag
    };

    /// <summary>
    /// Bir kategoriyi item türüne eþler (Python'daki kind_for'un karþýlýðý).
    /// Sýralama önemli: önce ayakkabý, sonra taký, sonra aksesuar; kalan her þey kýyafet.
    /// </summary>
    public static ItemKind ToKind(this Category category)
    {
        if (ShoeCategories.Contains(category)) return ItemKind.Shoes;
        if (JewelryCategories.Contains(category)) return ItemKind.Jewelry;
        if (AccessoryCategories.Contains(category)) return ItemKind.Accessory;
        return ItemKind.Clothing;
    }
}