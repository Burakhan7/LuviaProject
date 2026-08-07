using Luvia.Application.DTOs;
using Luvia.Application.Features.Wardrobe;
using Luvia.Application.Interfaces;
using Luvia.Infrastructure.Repositories;
using Luvia.Infrastructure.Services;
using Luvia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Luvia.Application.Features.Outfits;
using Luvia.Application.DTOs;
using Luvia.Domain.Enums;
using Luvia.Infrastructure.Services;
using System.Text.Json;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter());
});

// ── DI kayıtları ──────────────────────────────────────────────
builder.Services.AddScoped<IImageAnalysisService, MockAnalysisService>();
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

var app = builder.Build();

// ── Endpoint: fotoğraf URL'inden item ekle ────────────────────
app.MapPost("/wardrobe/items", async (
    AddItemRequest request,
    AddWardrobeItemHandler handler,
    CancellationToken ct) =>
{
    var item = await handler.HandleAsync(request, ct);
    return Results.Ok(item);
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

app.MapGet("/outfits/{userId}", async (
    string userId,
    Season season,
    Formality formality,
    IWardrobeItemRepository repo,
    IOutfitRecommender recommender,
    CancellationToken ct) =>
{
    var wardrobe = await repo.GetByUserAsync(userId, ct);
    var context = new OutfitContext(season, formality);
    var outfits = recommender.Recommend(wardrobe, context);

    // Sade bir çıktı — sadece kategori/renk + skor + gerekçe
    var response = outfits.Select(o => new
    {
        score = Math.Round(o.Score, 2),
        items = o.Items.Select(i => new { i.Category, i.Color, i.Style }),
        reasons = o.Reasons
    });

    return Results.Ok(response);
});

app.Run();