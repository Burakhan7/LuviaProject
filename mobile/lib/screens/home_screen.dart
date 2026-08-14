import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/services/weather_service.dart';
import '../models/wardrobe_item.dart';
import '../models/outfit.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  final _weather = WeatherService();
  late Future<List<WardrobeItem>> _wardrobeFuture;
  Future<OutfitResult>? _outfitFuture;

  WeatherResult? _currentWeather;
  DailyForecast? _todayForecast; // ← YENİ
  WeatherStatus? _forecastStatus; // ← YENİ: neden yok, onu bilelim
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _wardrobeFuture = _api.getWardrobe();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final outcome = await _weather.getWeather();
    final forecastOutcome = await _weather.getTodayForecast();
    if (mounted) {
      setState(() {
        _currentWeather = outcome.result;
        _todayForecast = forecastOutcome.forecast;
        _forecastStatus = forecastOutcome.status;
      });
    }
  }

  void refresh() {
    setState(() {
      _wardrobeFuture = _api.getWardrobe();
    });
  }

  // Varsayılan bağlamla kombin öner
  void _suggestOutfit() {
    // Forecast varsa günün geneline göre, yoksa anlık, o da yoksa aya göre
    final season =
        _todayForecast?.season ??
        _currentWeather?.season ??
        WeatherService.seasonFromMonth();
    setState(() {
      _outfitFuture = _api.getOutfits(season, 'Casual');
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (6 < h && h < 12) return 'Günaydın';
    if (h > 12 && h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  Widget _guestBanner(int itemCount) {
    // Sadece misafirse göster; gerçek kullanıcıya hiç gösterme
    if (!_auth.isGuest) return const SizedBox.shrink();

    // Kıyafet sayısına göre mesaj tonu artar
    String msg;
    Color bgColor;
    if (itemCount == 0) {
      msg =
          'Misafir modundasın. Kaydol veya Giriş yap, kıyafetlerini kalıcı olarak sakla.';
      bgColor = LuviaTheme.primary.withValues(alpha: 0.08);
    } else if (itemCount < 10) {
      msg =
          '$itemCount kıyafetin var. Kaydolmazsan kaybolabilir — hesabını güvene al.';
      bgColor = Colors.orange.withValues(alpha: 0.12);
    } else {
      msg =
          '$itemCount kıyafet biriktirdin! Bunları kaybetmemek için hemen kaydol.';
      bgColor = Colors.red.withValues(alpha: 0.10);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: LuviaTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _openAuth,
            style: FilledButton.styleFrom(
              backgroundColor: LuviaTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Kaydol veya Giriş Yap',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAuth() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
    // Kayıt/giriş sonrası dönünce ekranı tazele (banner kaybolsun, veriler güncellensin)
    if (mounted) {
      setState(() {
        _wardrobeFuture = _api.getWardrobe();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<WardrobeItem>>(
        future: _wardrobeFuture,
        builder: (context, snap) {
          final items = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Luvia',
                    style: TextStyle(
                      fontSize: 26,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: LuviaTheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _greeting,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  if (_currentWeather != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            size: 14,
                            color: LuviaTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentWeather!.temp.round()}°  ${_currentWeather!.city ?? ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              _guestBanner(items.length),
              _forecastCard(), // ← YENİ: bugün hava böyle ilerleyecek
              const SizedBox(height: 20),
              const Text(
                'Bugün ne giysek?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // HERO — Bugünün Kombini (canlı)
              _heroCard(),
              const SizedBox(height: 20),

              // Hızlı aksiyon — Kıyafet Ekle
              _quickAdd(),
              const SizedBox(height: 24),

              // Gardırop özeti (küçük, şık)
              _wardrobeSummary(items),
              const SizedBox(height: 28),

              // Son eklenenler (en altta)
              const Text(
                'Son Eklenenler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              _recent(snap, items),
            ],
          );
        },
      ),
    );
  }

  Widget _forecastCard() {
    final f = _todayForecast;
    if (f == null)
      return _weatherPermissionCard(); // forecast yoksa hiçbir şey gösterme

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.wb_cloudy_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                f.city != null ? 'Bugün · ${f.city}' : 'Bugün',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${f.minTemp.round()}° / ${f.maxTemp.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            f.advice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherPermissionCard() {
    // Konum servisi kapalıysa veya izin yoksa davet göster.
    // Hata/bilinmeyen durumda hiçbir şey gösterme (kullanıcıyı boşuna rahatsız etme).
    if (_forecastStatus == null || _forecastStatus == WeatherStatus.error) {
      return const SizedBox.shrink();
    }

    String msg;
    if (_forecastStatus == WeatherStatus.serviceDisabled) {
      msg = 'Konum servisin kapalı. Aç, günün havasına göre kombin önerelim.';
    } else {
      msg = 'Konum izni ver, günün gidişatına göre sana kombin önerelim.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LuviaTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: LuviaTheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hava durumuna göre öneri',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  msg,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _requestLocationPermission,
            style: FilledButton.styleFrom(
              backgroundColor: LuviaTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    if (_forecastStatus == WeatherStatus.serviceDisabled) {
      // Konum servisi kapalı → sistem ayarlarına yönlendir
      await Geolocator.openLocationSettings();
    } else if (_forecastStatus == WeatherStatus.deniedForever) {
      // Kalıcı red → uygulama ayarlarına
      await Geolocator.openAppSettings();
    } else {
      // Normal red → izin iste
      await Geolocator.requestPermission();
    }
    // Kullanıcı ayarlardan dönünce tekrar dene
    _loadWeather();
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [LuviaTheme.primary, LuviaTheme.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: LuviaTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Bugünün Kombini',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kombin sonucu / buton
          if (_outfitFuture == null) _heroPrompt() else _heroResult(),
        ],
      ),
    );
  }

  Widget _heroPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gardırobuna göre sana özel bir kombin önerelim',
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _suggestOutfit,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: LuviaTheme.primary,
            ),
            child: const Text('Kombin Oluştur'),
          ),
        ),
      ],
    );
  }

  Widget _heroResult() {
    return FutureBuilder<OutfitResult>(
      future: _outfitFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        final result = snap.data;
        final outfits = result?.outfits ?? [];
        if (outfits.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kombin oluşturmak için daha fazla kıyafet ekle',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
              const SizedBox(height: 12),
              _heroSmallButton('Tekrar Dene', _suggestOutfit),
            ],
          );
        }
        final outfit = outfits.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: outfit.items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final item = outfit.items[i];
                  return Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.processedImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: item.processedImageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth:
                                300, // gösterilecek boyutta cache — bellek + hız
                            placeholder: (context, url) =>
                                Container(color: LuviaTheme.bgTop),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.checkroom),
                          )
                        : const Icon(
                            Icons.checkroom,
                            color: LuviaTheme.primary,
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Uyum %${(outfit.score * 100).round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _suggestOutfit,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Yenile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _heroSmallButton(String label, VoidCallback onTap) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: LuviaTheme.primary,
    ),
    child: Text(label),
  );

  Widget _quickAdd() {
    return GestureDetector(
      onTap: () => widget.onNavigateToTab?.call(1), // Galeri sekmesi
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LuviaTheme.bgTop,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add_a_photo, color: LuviaTheme.primary),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yeni bir şey mi aldın?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Dolabına ekle, kombinlerde çıksın',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  Widget _wardrobeSummary(List<WardrobeItem> items) {
    final total = items.length;
    final ust = items
        .where(
          (i) =>
              i.kind == 'Clothing' &&
              {
                'TShirt',
                'Shirt',
                'Sweater',
                'Hoodie',
                'Cardigan',
                'Jacket',
                'Coat',
                'Blazer',
              }.contains(i.category),
        )
        .length;
    final alt = items
        .where(
          (i) =>
              i.kind == 'Clothing' &&
              {
                'Jeans',
                'Pants',
                'Shorts',
                'Skirt',
                'Sweatpants',
              }.contains(i.category),
        )
        .length;
    final ayakkabi = items.where((i) => i.kind == 'Shoes').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          _summaryStat('$total', 'Toplam'),
          _summaryDivider(),
          _summaryStat('$ust', 'Üst'),
          _summaryDivider(),
          _summaryStat('$alt', 'Alt'),
          _summaryDivider(),
          _summaryStat('$ayakkabi', 'Ayakkabı'),
        ],
      ),
    );
  }

  Widget _summaryStat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: LuviaTheme.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _summaryDivider() =>
      Container(width: 1, height: 30, color: Colors.black12);

  Widget _recent(AsyncSnapshot snap, List<WardrobeItem> items) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.checkroom, size: 36, color: Colors.black26),
            SizedBox(height: 8),
            Text(
              'Henüz kıyafet eklemedin',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length > 10 ? 10 : items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: item.processedImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.processedImageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth:
                              300, // gösterilecek boyutta cache — bellek + hız
                          placeholder: (context, url) =>
                              Container(color: LuviaTheme.bgTop),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.checkroom),
                        )
                      : Container(
                          color: LuviaTheme.bgTop,
                          child: const Icon(
                            Icons.checkroom,
                            color: LuviaTheme.primary,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    '${item.color} ${item.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
