// Repositories/InMemoryWardrobeItemRepository.cs
using Luvia.Application.Interfaces;
using Luvia.Domain.Entities;

namespace Luvia.Infrastructure.Repositories;

/// <summary>
/// Geçici bellek-içi depo. EF Core hazýr olunca EfWardrobeItemRepository ile deðiþecek.
/// Singleton olarak kaydedilmeli ki veri istekler arasýnda yaþasýn.
/// </summary>
public class InMemoryWardrobeItemRepository : IWardrobeItemRepository
{
    private readonly List<WardrobeItem> _items = new();

    public Task AddAsync(WardrobeItem item, CancellationToken ct = default)
    {
        _items.Add(item);
        return Task.CompletedTask;
    }

    public Task<List<WardrobeItem>> GetByUserAsync(string userId, CancellationToken ct = default)
        => Task.FromResult(_items.Where(i => i.UserId == userId).ToList());

    public Task<WardrobeItem?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => Task.FromResult(_items.FirstOrDefault(i => i.Id == id));

    public Task SaveChangesAsync(CancellationToken ct = default)
        => Task.CompletedTask;   // bellekte SaveChanges no-op; EF Core'da gerçek olacak
    public Task DeleteAsync(WardrobeItem item, CancellationToken ct = default)
    {
        _items.Remove(item);
        return Task.CompletedTask;
    }
}