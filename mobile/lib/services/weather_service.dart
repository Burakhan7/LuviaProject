// lib/services/weather_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/l10n/app_localizations.dart';

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
  final int hour;
  final double temp;
  final String
  condition; // "Clear","Clouds","Rain","Snow","Drizzle","Thunderstorm"
  final int pop; // yağmur ihtimali % (0-100)
  HourSlot(this.hour, this.temp, this.condition, this.pop);
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

  /// Baktığın saatten sonraki zaman dilimlerinin hava durumu (yorumlu).
  String get slotAdvice {
    final now = DateTime.now().hour;

    // 4 dilim: Sabah 6-11, Öğle 11-17, Akşam 17-22, Gece 22-6
    final dilimler = [
      ('Sabah', 6, 11),
      ('Öğle', 11, 17),
      ('Akşam', 17, 22),
      ('Gece', 22, 30), // 22-06 (ertesi gün) — 30 = 24+6
    ];

    // Her dilimin ortalama sıcaklığını hesapla
    String? dilimSicaklik(int start, int end) {
      final temps = slots
          .where((s) {
            final h = s.hour < 6 ? s.hour + 24 : s.hour; // gece sarması
            return h >= start && h < end;
          })
          .map((s) => s.temp)
          .toList();
      if (temps.isEmpty) return null;
      final avg = temps.reduce((a, b) => a + b) / temps.length;
      return '${avg.round()}°';
    }

    // Sıcaklığa göre kısa yorum
    String yorum(double t) {
      if (t >= 28) return 'sıcak';
      if (t >= 22) return 'ılık';
      if (t >= 16) return 'serin';
      if (t >= 10) return 'soğukça';

      return 'soğuk';
    }

    // Baktığın saatten SONRAKI dilimleri topla
    final parts = <String>[];
    for (final (isim, start, end) in dilimler) {
      // Bu dilim şu andan sonra mı başlıyor/devam ediyor?
      final nowAdj = now < 6 ? now + 24 : now;
      if (end <= nowAdj) continue; // geçmiş dilim, atla

      final temps = slots
          .where((s) {
            final h = s.hour < 6 ? s.hour + 24 : s.hour;
            return h >= start && h < end;
          })
          .map((s) => s.temp)
          .toList();
      if (temps.isEmpty) continue;
      final avg = temps.reduce((a, b) => a + b) / temps.length;
      parts.add('$isim ${yorum(avg)} ${avg.round()}°');
    }

    if (parts.isEmpty) return advice; // dilim yoksa gün geneli
    return parts.join(', ');
  }

  /// Kullanıcının girdiği dilimden itibaren 4-dilim zengin hava metni.
  String richAdvice(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now().hour;

    // Dilimler: (isim-key, başlangıç, bitiş)
    final dilimler = [
      ('morning', 6, 12), // Sabah-öğle
      ('afternoon', 12, 16), // Öğleden sonra
      ('evening', 16, 20), // Akşam üstü
      ('night', 20, 24), // Akşam
    ];

    String dilimAdi(String key) {
      switch (key) {
        case 'morning':
          return t.slotMorning;
        case 'afternoon':
          return t.slotAfternoon;
        case 'evening':
          return t.slotEvening;
        case 'night':
          return t.slotNight;
        default:
          return '';
      }
    }

    String durumMetni(String cond) {
      switch (cond) {
        case 'Rain':
        case 'Drizzle':
          return t.weatherRainy;
        case 'Clouds':
          return t.weatherCloudy;
        case 'Clear':
          return t.weatherClear;
        case 'Snow':
          return t.weatherSnowy;
        case 'Thunderstorm':
          return t.weatherStorm;
        default:
          return t.weatherCloudy;
      }
    }

    // Akıllı öneri (senin inisiyatifime bıraktığın)
    String oneri(double temp, int pop, String cond) {
      if (pop >= 40 && temp < 16) return t.tipUmbrellaJacket; // şemsiye + ceket
      if (pop >= 40) return t.tipUmbrella; // şemsiye
      if (temp < 10) return t.tipHeavy; // kalın giyin
      if (temp < 16) return t.tipLightJacket; // hafif ceket
      if (temp > 26) return t.tipLight; // hafif giyin
      return t.tipNice; // güzel hava
    }

    final parts = <String>[];
    for (final (key, start, end) in dilimler) {
      if (end <= now) continue; // geçmiş dilim → atla

      final dilimSlots = slots
          .where((s) => s.hour >= start && s.hour < end)
          .toList();
      if (dilimSlots.isEmpty) continue;

      final avgTemp =
          dilimSlots.map((s) => s.temp).reduce((a, b) => a + b) /
          dilimSlots.length;
      final maxPop = dilimSlots
          .map((s) => s.pop)
          .reduce((a, b) => a > b ? a : b);
      // Dilimin baskın durumu (ilk slot yeterli, ya da en kötü)
      final cond = dilimSlots.first.condition;

      final ad = dilimAdi(key);
      final durum = durumMetni(cond);
      final tip = oneri(avgTemp, maxPop, cond);
      final popText = maxPop >= 20 ? ' %$maxPop' : '';

      // "Akşam üstü (16-20) 20° $durum$popText. $tip"
      parts.add(
        '$ad (${start}-${end}) ${avgTemp.round()}°$popText $durum. $tip',
      );
    }

    if (parts.isEmpty) return advice; // dilim kalmadıysa gün geneli
    return parts.join('\n');
  }

  /// Ana sayfa için: 8-21 arası min/max + baskın durum (tüm gün mantığı)
  (double, double, String) dayRange() {
    return _rangeFor(8, 21);
  }

  /// Kombin ekranı için: şu andan gün sonuna min/max + baskın durum (o an+sonrası)
  (double, double, String) fromNowRange() {
    final now = DateTime.now().hour;
    return _rangeFor(now, 24);
  }

  /// Belirli saat aralığı için min/max sıcaklık + baskın hava durumu
  (double, double, String) _rangeFor(int start, int end) {
    final inRange = slots.where((s) {
      final h = s.hour < 6 ? s.hour + 24 : s.hour;
      return h >= start && h < end;
    }).toList();

    if (inRange.isEmpty) {
      return (minTemp, maxTemp, 'Clear'); // veri yoksa gün geneli
    }

    final mn = inRange.map((s) => s.temp).reduce((a, b) => a < b ? a : b);
    final mx = inRange.map((s) => s.temp).reduce((a, b) => a > b ? a : b);

    // Baskın durum: bir dilimin TAMAMI yağmursa yağmur, değilse en sık
    final conds = inRange.map((s) => s.condition).toList();
    final bad = ['Rain', 'Drizzle', 'Snow', 'Thunderstorm'];
    // Tüm dilim kötü havaysa onu seç
    if (conds.every((c) => bad.contains(c))) {
      // en kötüsünü öncelikle (Storm > Snow > Rain)
      if (conds.contains('Thunderstorm')) return (mn, mx, 'Thunderstorm');

      if (conds.contains('Snow')) return (mn, mx, 'Snow');
      return (mn, mx, 'Rain');
    }
    // Değilse en sık durum
    final freq = <String, int>{};
    for (final c in conds) {
      freq[c] = (freq[c] ?? 0) + 1;
    }
    final dominant = freq.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    return (mn, mx, dominant);
  }

  /// Çıkış saatinden (baktığın saat + hazırlık payı) sonraki min/max sıcaklık.
  /// Kombin motoru bununla katman kararı verir.
  (double, double) get outboundMinMax {
    final now = DateTime.now().hour;
    // Hazırlık payı: kullanıcı ~2 saat sonra çıkar (sabah erkense biraz daha)
    int cikis = now + 2;
    if (now >= 6 && now < 10) cikis = 12; // sabah 6-10 → en geç 12'de çıkar
    if (cikis > 23) cikis = now; // gece ise şu andan itibaren

    final temps = slots
        .where((s) {
          final h = s.hour < 6 ? s.hour + 24 : s.hour;
          final c = cikis < 6 ? cikis + 24 : cikis;
          return h >= c;
        })
        .map((s) => s.temp)
        .toList();

    if (temps.isEmpty) {
      // Çıkış sonrası dilim yoksa → tüm günün min/max'ı
      return (minTemp, maxTemp);
    }
    final mn = temps.reduce((a, b) => a < b ? a : b);
    final mx = temps.reduce((a, b) => a > b ? a : b);
    return (mn, mx);
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
        final cond = (item['weather']?[0]?['main'] as String?) ?? 'Clear';
        final pop = (((item['pop'] as num?) ?? 0) * 100).round();
        slots.add(HourSlot(dt.hour, t, cond, pop));
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
          final cond = (item['weather']?[0]?['main'] as String?) ?? 'Clear';
          final pop = (((item['pop'] as num?) ?? 0) * 100).round();
          slots.add(HourSlot(dt.hour, t, cond, pop));
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
