// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wardrobe_item.dart';

class ApiService {
  // Chrome'da test: localhost. (Android emülatörde 10.0.2.2 olur, sonra ayarlarız.)
  static const String baseUrl = 'http://localhost:5058';

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
}
