// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile/models/outfit.dart';
import '../models/wardrobe_item.dart';

class ApiService {
  // Chrome'da test: localhost. (Android emülatörde 10.0.2.2 olur, sonra ayarlarız.)
  static const String baseUrl = 'http://192.168.1.37:5058';

  // Şimdilik sabit test kullanıcısı (auth sonra)
  static const String testUserId = 'burak';

  Future<List<WardrobeItem>> getWardrobe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wardrobe/items/$testUserId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Gardırop yüklenemedi: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => WardrobeItem.fromJson(json)).toList();
  }

  /// Tek parça ekle (tek foto)
  Future<void> addItem(String imageUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': testUserId, 'originalImageUrl': imageUrl}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Parça eklenemedi: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Boydan fotodan çoklu parça ekle
  Future<void> addFullbody(String imageUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe/items/fullbody'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': testUserId, 'originalImageUrl': imageUrl}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Kombin eklenemedi: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Outfit>> getOutfits(String season, String formality) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/outfits/$testUserId?season=$season&formality=$formality',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Kombin önerisi alınamadı: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Outfit.fromJson(json)).toList();
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

  Future<void> deleteItem(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wardrobe/items/$id'),
    );
    if (response.statusCode != 200) {
      throw Exception('Silinemedi: ${response.statusCode}');
    }
  }
}
