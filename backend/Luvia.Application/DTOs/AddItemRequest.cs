// DTOs/AddItemRequest.cs
namespace Luvia.Application.DTOs;

public record AddItemRequest(string UserId, string OriginalImageUrl);
public record AvailabilityRequest(bool IsAvailable);