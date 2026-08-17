using Luvia.Application.DTOs;
using Luvia.Application.Features.Wardrobe;
using Luvia.Application.Interfaces;
using Luvia.Infrastructure.Repositories;
using Luvia.Infrastructure.Services;
using Luvia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Luvia.Application.Features.Outfits;
using Luvia.Domain.Enums;
using System.Text.Json;
using System.Text.Json.Serialization;
using Luvia.Domain.Entities;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter());
});

// ── DI kayıtları ──────────────────────────────────────────────
//builder.Services.AddScoped<IImageAnalysisService, MockAnalysisService>();
builder.Services.AddScoped<IOutfitRecommender, RuleBasedRecommender>();
builder.Services.AddScoped<IWardrobeItemRepository, EfWardrobeItemRepository>();
builder.Services.AddScoped<AddWardrobeItemHandler>();
builder.Services.AddDbContext<LuviaDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("Default")));
builder.Services.AddHttpClient<IImageAnalysisService, PythonCvAnalysisService>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["CvService:BaseUrl"]!);
    client.Timeout = TimeSpan.FromSeconds(30);   // CV işlemi biraz sürebilir
})
.AddTypedClient<IImageAnalysisService>((httpClient, sp) =>
    new PythonCvAnalysisService(httpClient));
builder.Services.AddScoped<AddFullbodyItemsHandler>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

// ── Otomatik migration: DB tablolarını oluştur/güncelle ──
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<LuviaDbContext>();
    db.Database.Migrate();
}

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("AllowAll");

// ── Endpoint: fotoğraf URL'inden item ekle ────────────────────
app.MapPost("/wardrobe/items", async (
    AddItemRequest request,
    AddWardrobeItemHandler handler,
    CancellationToken ct) =>
{
    var item = await handler.HandleAsync(request, ct);
    return Results.Ok(item);
});
// ── Endpoint: boydan fotoğraftan çoklu item ekle ──
app.MapPost("/wardrobe/items/fullbody", async (
    AddItemRequest request,
    AddFullbodyItemsHandler handler,
    CancellationToken ct) =>
{
    var items = await handler.HandleAsync(request, ct);
    return Results.Ok(items);
});

// ── Endpoint: kullanıcının gardırobunu listele ────────────────
app.MapGet("/wardrobe/items/{userId}", async (
    string userId,
    IWardrobeItemRepository repo,
    CancellationToken ct) =>
{
    var items = await repo.GetByUserAsync(userId, ct);
    return Results.Ok(items);
});

app.MapDelete("/wardrobe/items/{id}", async (
    Guid id,
    IWardrobeItemRepository repo,
    IImageAnalysisService analysis,        // ← eklendi
    CancellationToken ct) =>
{
    var item = await repo.GetByIdAsync(id, ct);
    if (item is null)
        return Results.NotFound();

    // Önce işlenmiş görseli Storage'dan sil (best-effort)
    if (!string.IsNullOrEmpty(item.ProcessedImageUrl))
    {
        await analysis.DeleteImageAsync(item.ProcessedImageUrl, ct);
    }

    // Sonra DB kaydını sil
    await repo.DeleteAsync(item, ct);
    await repo.SaveChangesAsync(ct);
    return Results.Ok();
});
// ── Endpoint: müsaitlik durumunu değiştir ──
app.MapPatch("/wardrobe/items/{id}/availability", async (
    Guid id,
    AvailabilityRequest body,
    IWardrobeItemRepository repo,
    CancellationToken ct) =>
{
    var item = await repo.GetByIdAsync(id, ct);
    if (item is null) return Results.NotFound();

    item.SetAvailability(body.IsAvailable);
    await repo.SaveChangesAsync(ct);
    return Results.Ok();
});

app.MapPatch("/wardrobe/items/{id}/correct", async (
    Guid id, CorrectRequest req,
    IWardrobeItemRepository repo, CancellationToken ct) =>
{
    var item = await repo.GetByIdAsync(id, ct);
    if (item is null) return Results.NotFound();
    item.CorrectAttributes(req.Category, req.Color, req.Season);
    await repo.SaveChangesAsync(ct);
    return Results.Ok();
});



app.MapGet("/outfits/{userId}", async (
    string userId, Season season, Formality formality,
    ColorName? preferredColor, Style? preferredStyle,
    int? offset,
    IWardrobeItemRepository repo, IOutfitRecommender recommender,
    CancellationToken ct) =>
{
    var wardrobe = await repo.GetByUserAsync(userId, ct);
    var context = new OutfitContext(season, formality, preferredColor, preferredStyle);
    var result = recommender.Recommend(wardrobe, context,5, offset ?? 0);   // ← OutfitResult

    // Eksik varsa: kombin yok, mesaj dön
    if (result.MissingMessage is not null)
    {
        return Results.Ok(new
        {
            outfits = Array.Empty<object>(),
            missingMessage = result.MissingMessage
        });
    }

    var outfits = result.Outfits.Select(o => new
    {
        score = Math.Round(o.Score, 2),
        items = o.Items.Select(i => new {
            i.Category,
            i.Color,
            i.Style,
            i.Kind,
            i.ProcessedImageUrl,
            i.IsLayered
        }),
        reasons = o.Reasons
    });

    return Results.Ok(new { outfits, missingMessage = (string?)null });
});

app.MapPost("/outfits/evaluate", async (
    EvaluateRequest req,
    IWardrobeItemRepository repo, IOutfitRecommender recommender,
    CancellationToken ct) =>
{
    // Kullanıcının gardırobunu çek
    var wardrobe = await repo.GetByUserAsync(req.UserId, ct);

    // Seçilen ID'lere karşılık gelen item'ları bul (sırayı koru, null'ları at)
    var selected = req.ItemIds
        .Select(id => wardrobe.FirstOrDefault(w => w.Id == id))
        .Where(i => i is not null)
        .Cast<WardrobeItem>()
        .ToList();

    // Hiç geçerli parça yoksa
    if (selected.Count == 0)
        return Results.BadRequest(new { message = "Değerlendirilecek geçerli parça bulunamadı." });

    // Context: mevsim/formalite değerlendirmede zorunlu değil, varsayılan ver
    var context = new OutfitContext(req.Season, Formality.Casual, null, null);

    var (score, reasons) = recommender.Evaluate(selected, context);

    return Results.Ok(new
    {
        score = (int)Math.Round(score * 100),   // 0.0-1.0 → 0-100
        comments = reasons
    });
});

app.MapGet("/outfits/{userId}/daily", async (
    string userId, Season season, Formality formality,
    IWardrobeItemRepository repo, IOutfitRecommender recommender,
    CancellationToken ct) =>
{
    var wardrobe = await repo.GetByUserAsync(userId, ct);
    var context = new OutfitContext(season, formality, null, null);
    var today = DateOnly.FromDateTime(DateTime.UtcNow);

    var outfit = recommender.RecommendDaily(wardrobe, context, today);

    if (outfit is null)
        return Results.Ok(new { outfit = (object?)null, message = "Kombin önerisi için yeterli parça yok." });

    var result = new
    {
        score = Math.Round(outfit.Score, 2),
        items = outfit.Items.Select(i => new {
            i.Category,
            i.Color,
            i.Style,
            i.Kind,
            i.ProcessedImageUrl,
            i.IsLayered
        }),
        reasons = outfit.Reasons
    };

    return Results.Ok(new { outfit = result, message = (string?)null });
});
app.MapDelete("/users/{userId}", async (
    string userId,
    IWardrobeItemRepository repo,
    CancellationToken ct) =>
{
    await repo.DeleteByUserAsync(userId, ct);
    return Results.Ok(new { message = "Hesap verileri silindi." });
});

app.Run();

record CorrectRequest(Category Category, ColorName Color, Season Season);
record AvailabilityRequest(bool IsAvailable);
record EvaluateRequest(string UserId, List<Guid> ItemIds, Season Season);