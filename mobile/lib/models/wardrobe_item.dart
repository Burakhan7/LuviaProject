// lib/models/wardrobe_item.dart
class WardrobeItem {
  final String id;
  final String category;
  final String color;
  final String kind;
  final String? processedImageUrl;
  final String? originalImageUrl;
  final String? style;
  final String? season;
  final bool isLayered;
  final bool needsReview;
  final bool isAvailable;

  WardrobeItem({
    required this.id,
    required this.category,
    required this.color,
    required this.kind,
    this.processedImageUrl,
    this.originalImageUrl,
    this.style,
    this.season,
    this.isLayered = false,
    this.needsReview = false,
    this.isAvailable = true,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      color: json['color'] ?? '',
      kind: json['kind'] ?? '',
      processedImageUrl: json['processedImageUrl'],
      originalImageUrl: json['originalImageUrl'],
      style: json['style'],
      season: json['season'],
      isLayered: json['isLayered'] ?? false,
      needsReview: json['needsReview'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
