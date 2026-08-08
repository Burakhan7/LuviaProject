// Repositories/EfWardrobeItemRepository.cs
using Luvia.Application.Interfaces;
using Luvia.Domain.Entities;
using Luvia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Luvia.Infrastructure.Repositories;

public class EfWardrobeItemRepository : IWardrobeItemRepository
{
    private readonly LuviaDbContext _db;

    public EfWardrobeItemRepository(LuviaDbContext db) => _db = db;

    public async Task AddAsync(WardrobeItem item, CancellationToken ct = default)
        => await _db.WardrobeItems.AddAsync(item, ct);

    public async Task<List<WardrobeItem>> GetByUserAsync(string userId, CancellationToken ct = default)
        => await _db.WardrobeItems
            .Where(i => i.UserId == userId)
            .OrderByDescending(i => i.CreatedAt)
            .ToListAsync(ct);

    public async Task<WardrobeItem?> GetByIdAsync(Guid id, CancellationToken ct = default)
        => await _db.WardrobeItems.FirstOrDefaultAsync(i => i.Id == id, ct);

    public async Task SaveChangesAsync(CancellationToken ct = default)
        => await _db.SaveChangesAsync(ct);
    public Task DeleteAsync(WardrobeItem item, CancellationToken ct = default)
    {
        _db.WardrobeItems.Remove(item);
        return Task.CompletedTask;
    }
}