import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // ← ekle
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.1.37:5058'; // kendi ayarın (emülatör/cihaz) https://api.luviaapp.uk

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

  Future<List<Outfit>> getOutfits(String season, String formality) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/outfits/$_userId?season=$season&formality=$formality',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Kombin önerisi alınamadı: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Outfit.fromJson(json)).toList();
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
}
