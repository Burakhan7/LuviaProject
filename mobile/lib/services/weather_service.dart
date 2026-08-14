// lib/services/weather_service.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

enum WeatherStatus { ok, serviceDisabled, denied, deniedForever, error }

class WeatherOutcome {
  final WeatherResult? result;
  final DailyForecast? forecast; // ← yeni: günlük tahmin
  final WeatherStatus status;
  WeatherOutcome(this.status, {this.result, this.forecast});
}

class WeatherResult {
  final double temp; // °C
  final String season; // backend enum: Winter/Summer/MidSeason
  final String? city;

  WeatherResult({required this.temp, required this.season, this.city});
}

class HourSlot {
  final int hour; // 0-23
  final double temp;
  HourSlot(this.hour, this.temp);
}

class DailyForecast {
  final double minTemp;
  final double maxTemp;
  final String season; // günün geneli (max'a göre)
  final String? city;
  final List<HourSlot> slots; // günün saatlik gidişatı

  DailyForecast({
    required this.minTemp,
    required this.maxTemp,
    required this.season,
    this.city,
    required this.slots,
  });

  /// Gün içindeki sıcaklık farkına göre insanca bir öneri metni üretir.
  String get advice {
    final range = maxTemp - minTemp;
    if (range >= 10) {
      return 'Gün içinde ${minTemp.round()}° ile ${maxTemp.round()}° arası değişecek. Katmanlı giyin — sabah üşümezsin, öğlen çıkarırsın.';
    }
    if (maxTemp >= 28) {
      return 'Gün boyu sıcak (${maxTemp.round()}°). Hafif ve serin tut.';
    }
    if (maxTemp <= 12) {
      return 'Gün boyu soğuk (en fazla ${maxTemp.round()}°). Kalın giyin.';
    }
    return 'Bugün ${minTemp.round()}° - ${maxTemp.round()}° arası, dengeli bir gün.';
  }
}

class WeatherService {
  // OpenWeatherMap API anahtarın
  static const String _apiKey = 'edfa72e71095537c75173cfe702d91bb';

  /// Ortak: konum izni + konum al. Başarılıysa Position, değilse status döner.
  Future<(Position?, WeatherStatus)> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return (null, WeatherStatus.serviceDisabled);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return (null, WeatherStatus.denied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return (null, WeatherStatus.deniedForever);
    }

    Position? pos;
    try {
      pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      return (null, WeatherStatus.error);
    }
    if (pos == null) return (null, WeatherStatus.error);
    return (pos, WeatherStatus.ok);
  }

  /// Anlık hava durumu (eski davranış — korundu).
  Future<WeatherOutcome> getWeather() async {
    final (pos, status) = await _getPosition();
    if (pos == null) return WeatherOutcome(status);

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&units=metric&appid=$_apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return WeatherOutcome(WeatherStatus.error);
      }

      final data = jsonDecode(response.body);
      final double temp = (data['main']['temp'] as num).toDouble();
      final String? city = data['name'] as String?;
      final String season = _tempToSeason(temp);

      return WeatherOutcome(
        WeatherStatus.ok,
        result: WeatherResult(temp: temp, season: season, city: city),
      );
    } catch (e) {
      return WeatherOutcome(WeatherStatus.error);
    }
  }

  /// Bugünün 3 saatlik dilimlerinden min/max ve gidişat çıkarır.
  Future<WeatherOutcome> getTodayForecast() async {
    final (pos, status) = await _getPosition();
    if (pos == null) return WeatherOutcome(status);

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&units=metric&appid=$_apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return WeatherOutcome(WeatherStatus.error);
      }

      final data = jsonDecode(response.body);
      final List list = data['list'] as List;
      final String? city = data['city']?['name'] as String?;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';

      final slots = <HourSlot>[];
      double minT = double.infinity;
      double maxT = double.negativeInfinity;

      for (final item in list) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          (item['dt'] as int) * 1000,
        );
        final itemStr = '${dt.year}-${dt.month}-${dt.day}';
        if (itemStr != todayStr) continue;

        final t = (item['main']['temp'] as num).toDouble();
        slots.add(HourSlot(dt.hour, t));
        if (t < minT) minT = t;
        if (t > maxT) maxT = t;
      }

      // Gece geç saatte bugüne ait dilim kalmadıysa → ilk 8 dilim (24 saat)
      if (slots.isEmpty) {
        for (final item in list.take(8)) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
            (item['dt'] as int) * 1000,
          );
          final t = (item['main']['temp'] as num).toDouble();
          slots.add(HourSlot(dt.hour, t));
          if (t < minT) minT = t;
          if (t > maxT) maxT = t;
        }
      }

      if (slots.isEmpty) return WeatherOutcome(WeatherStatus.error);

      // Mevsimi günün MAX'ına göre belirle (en sıcak ana hazırlıklı ol)
      final season = _tempToSeason(maxT);

      return WeatherOutcome(
        WeatherStatus.ok,
        forecast: DailyForecast(
          minTemp: minT,
          maxTemp: maxT,
          season: season,
          city: city,
          slots: slots,
        ),
      );
    } catch (e) {
      return WeatherOutcome(WeatherStatus.error);
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

    final isSummerMonth = month >= 6 && month <= 8;
    final isWinterMonth = month == 12 || month <= 2;

    if (isSummerMonth) {
      if (temp >= 18) return 'Summer';
      return 'MidSeason';
    }
    if (isWinterMonth) {
      if (temp <= 14) return 'Winter';
      return 'MidSeason';
    }
    if (temp <= 12) return 'Winter';
    if (temp >= 23) return 'Summer';
    return 'MidSeason';
  }
}
