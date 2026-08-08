// lib/models/outfit.dart
import 'wardrobe_item.dart';

class Outfit {
  final double score;
  final List<WardrobeItem> items;
  final List<String> reasons;

  Outfit({required this.score, required this.items, required this.reasons});

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      score: (json['score'] ?? 0).toDouble(),
      items: (json['items'] as List? ?? [])
          .map((i) => WardrobeItem.fromJson(i))
          .toList(),
      reasons: (json['reasons'] as List? ?? [])
          .map((r) => r.toString())
          .toList(),
    );
  }
}
