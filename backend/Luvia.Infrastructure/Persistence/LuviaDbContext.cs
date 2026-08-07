// Persistence/LuviaDbContext.cs
using Luvia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using System.Reflection;

namespace Luvia.Infrastructure.Persistence;

public class LuviaDbContext : DbContext
{
    public LuviaDbContext(DbContextOptions<LuviaDbContext> options) : base(options) { }

    public DbSet<WardrobeItem> WardrobeItems => Set<WardrobeItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Bu assembly'deki tüm IEntityTypeConfiguration'larý otomatik uygula
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
        base.OnModelCreating(modelBuilder);
    }
}