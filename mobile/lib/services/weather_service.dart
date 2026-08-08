// lib/services/weather_service.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherResult {
  final double temp; // °C
  final String season; // backend enum: Winter/Summer/MidSeason
  final String? city;

  WeatherResult({required this.temp, required this.season, this.city});
}

class WeatherService {
  // OpenWeatherMap API anahtarın
  static const String _apiKey = 'edfa72e71095537c75173cfe702d91bb';

  /// Konum izni ister, konumu alır, sıcaklığı çeker.
  /// İzin verilmezse ya da hata olursa null döner (buton aktif olmaz).
  Future<WeatherResult?> getWeather() async {
    // 1) Konum servisi açık mı?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // 2) İzin durumu
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // izin iste
      if (permission == LocationPermission.denied) return null; // yine reddetti
    }
    if (permission == LocationPermission.deniedForever) {
      return null; // kalıcı reddetmiş, açamayız
    }

    // 3) Konumu al
    // Önce son bilinen konumu dene (anlık)
    Position? pos;
    try {
      pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      return null;
    }
    if (pos == null) return null;

    // 4) OpenWeather'dan sıcaklık
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&units=metric&appid=$_apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final temp = (data['main']?['temp'] as num?)?.toDouble();
      final city = data['name'] as String?;
      if (temp == null) return null;

      return WeatherResult(temp: temp, season: _tempToSeason(temp), city: city);
    } catch (e) {
      return null;
    }
  }

  /// Konum/hava yoksa: sadece takvim ayından mevsim tahmini (kuzey yarımküre)
  static String seasonFromMonth() {
    final month = DateTime.now().month;
    if (month >= 6 && month <= 8) return 'Summer'; // Haz-Tem-Ağu
    if (month == 12 || month <= 2) return 'Winter'; // Ara-Oca-Şub
    return 'MidSeason'; // İlkbahar / Sonbahar
  }

  static String _tempToSeason(double temp) {
    final month = DateTime.now().month;

    // Ay bazlı kaba mevsim (kuzey yarımküre)
    final isSummerMonth = month >= 6 && month <= 8; // Haz-Tem-Ağu
    final isWinterMonth = month == 12 || month <= 2; // Ara-Oca-Şub

    // Yaz ayında gece soğusa bile Kış deme
    if (isSummerMonth) {
      if (temp >= 18) return 'Summer';
      return 'MidSeason'; // yaz gecesi serinliği → en fazla Ara Mevsim
    }

    // Kış ayında gündüz ısınsa bile Yaz deme
    if (isWinterMonth) {
      if (temp <= 14) return 'Winter';
      return 'MidSeason'; // ılık kış günü → en fazla Ara Mevsim
    }

    // Ara aylar (İlkbahar/Sonbahar) — sıcaklık belirleyici
    if (temp <= 12) return 'Winter';
    if (temp >= 23) return 'Summer';
    return 'MidSeason';
  }
}
