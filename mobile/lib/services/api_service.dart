import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // ← ekle
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';

class ApiService {
  static const String baseUrl =
      'https://api.luviaapp.uk'; // kendi ayarın (emülatör/cihaz) https://api.luviaapp.uk http://192.168.1.37:5058

  // Giriş yapmış kullanıcının UID'si (sabit 'burak' yerine)
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<List<WardrobeItem>> getWardrobe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wardrobe/items/$_userId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Gardırop yüklenemedi: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => WardrobeItem.fromJson(json)).toList();
  }

  Future<void> addItem(String imageUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': _userId, 'originalImageUrl': imageUrl}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Parça eklenemedi: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> addFullbody(String imageUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe/items/fullbody'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': _userId, 'originalImageUrl': imageUrl}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Kombin eklenemedi: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<OutfitResult> getOutfits(
    String season,
    String formality, {
    String? preferredColor, // isteğe bağlı
    String? preferredStyle, // isteğe bağlı
    int offset = 0, // sonraki 5 için
  }) async {
    // Query parametrelerini oluştur
    final params = <String, String>{
      'season': season,
      'formality': formality,
      'offset': offset.toString(),
    };
    if (preferredColor != null) params['preferredColor'] = preferredColor;
    if (preferredStyle != null) params['preferredStyle'] = preferredStyle;

    final uri = Uri.parse(
      '$baseUrl/outfits/$_userId',
    ).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Kombin önerisi alınamadı: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);

    // Eksik mesajı varsa
    final missingMessage = data['missingMessage'] as String?;

    // Kombinleri parse et
    final List<dynamic> outfitsJson = data['outfits'] ?? [];
    final outfits = outfitsJson.map((json) => Outfit.fromJson(json)).toList();

    return OutfitResult(outfits: outfits, missingMessage: missingMessage);
  }

  Future<void> deleteItem(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wardrobe/items/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Silinemedi: ${response.statusCode}');
    }
  }

  Future<void> setAvailability(String id, bool isAvailable) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/wardrobe/items/$id/availability'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'isAvailable': isAvailable}),
    );
    if (response.statusCode != 200) {
      throw Exception('Güncellenemedi: ${response.statusCode}');
    }
  }

  Future<void> correctItem(
    String id,
    String category,
    String color,
    String season,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/wardrobe/items/$id/correct'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'category': category,
        'color': color,
        'season': season,
      }),
    );
    if (response.statusCode != 200)
      throw Exception('Düzeltilemedi: ${response.statusCode}');
  }

  // Manuel kombin değerlendirme — seçilen parçaları backend'e gönderir, skor + yorum alır
  Future<({int score, List<String> comments})> evaluateOutfit(
    List<String> itemIds,
    String season,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/outfits/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': _userId,
        'itemIds': itemIds,
        'season': season,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Değerlendirme yapılamadı: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    final score = data['score'] as int;
    final comments = (data['comments'] as List<dynamic>)
        .map((c) => c.toString())
        .toList();

    return (score: score, comments: comments);
  }
}
