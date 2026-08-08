// Interfaces/IWardrobeItemRepository.cs
using Luvia.Domain.Entities;

namespace Luvia.Application.Interfaces;

/// <summary>
/// Gardýrop item'larýnýn kalýcýlýk sözleþmesi.
/// Implementasyonu Infrastructure'da (EF Core + MSSQL) olacak.
/// </summary>
public interface IWardrobeItemRepository
{
    Task AddAsync(WardrobeItem item, CancellationToken ct = default);
    Task<List<WardrobeItem>> GetByUserAsync(string userId, CancellationToken ct = default);
    Task<WardrobeItem?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task SaveChangesAsync(CancellationToken ct = default);
    Task DeleteAsync(WardrobeItem item, CancellationToken ct = default);
}