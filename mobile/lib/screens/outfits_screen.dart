// lib/screens/outfits_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/outfit.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../services/weather_service.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});
  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  final _api = ApiService();
  Future<OutfitResult>? _future;
  final _weather = WeatherService();

  String _season = 'MidSeason';
  String _formality = 'Casual';
  bool _useWeather = false; // ← toggle durumu
  WeatherResult? _weatherResult;
  bool _weatherLoading = false;
  bool _useColor = false; // renk toggle açık mı
  String? _selectedColor; // seçilen renk
  bool _useStyle = false; // stil toggle açık mı
  String? _selectedStyle; // seçilen stil
  int _offset = 0; // şu anki offset
  String? _lastContextKey; // son kullanılan bağlam (değişti mi anlamak için)
  String _currentContextKey() {
    final color = _useColor ? _selectedColor : null;
    final style = _useStyle ? _selectedStyle : null;
    return '$_season|$_formality|$color|$style';
  }

  String get _buttonLabel {
    // Aynı bağlamda daha önce öneri alındıysa "Başka Öner"
    final sameContext = _currentContextKey() == _lastContextKey;
    return sameContext ? 'Başka Öner' : 'Kombin Oluştur';
  }

  final _colors = {
    'Black': 'Siyah',
    'White': 'Beyaz',
    'Gray': 'Gri',
    'Red': 'Kırmızı',
    'Burgundy': 'Bordo',
    'Orange': 'Turuncu',
    'Yellow': 'Sarı',
    'Green': 'Yeşil',
    'Khaki': 'Haki',
    'Blue': 'Mavi',
    'Navy': 'Lacivert',
    'Turquoise': 'Turkuaz',
    'Purple': 'Mor',
    'Pink': 'Pembe',
    'Brown': 'Kahve',
    'Beige': 'Bej',
    'Cream': 'Krem',
  };
  final _styles = {
    'Casual': 'Günlük',
    'Sporty': 'Sportif',
    'Classic': 'Klasik',
    'Streetwear': 'Sokak',
    'Minimal': 'Minimal',
    'Bohemian': 'Bohem',
  };

  void _onContextChanged() {
    setState(() {
      _offset = 0;
      _lastContextKey = null; // bağlam sıfırlandı işareti
    });
  }

  void _generate() {
    final contextKey = _currentContextKey();

    if (contextKey == _lastContextKey) {
      // Aynı bağlam → sonraki 5
      _offset += 5;
      if (_offset > 10) {
        // 4. basış → yeterli (0,5,10 kullanıldı, 15 sınır)
        _offset = 10;
        // İstersen kullanıcıya "hepsi bu kadar" mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu bağlam için yeterince öneri gösterdik'),
          ),
        );
        return;
      }
    } else {
      // Bağlam değişti → baştan başla
      _offset = 0;
      _lastContextKey = contextKey;
    }

    setState(() {
      _future = _api.getOutfits(
        _season,
        _formality,
        preferredColor: _useColor ? _selectedColor : null,
        preferredStyle: _useStyle ? _selectedStyle : null,
        offset: _offset, // ← offset'i geçir
      );
    });
  }

  Future<void> _toggleWeather(bool value) async {
    if (!value) {
      setState(() => _useWeather = false);
      return;
    }
    setState(() => _weatherLoading = true);
    final outcome = await _weather.getWeather();
    if (!mounted) return;
    setState(() => _weatherLoading = false);

    if (outcome.status != WeatherStatus.ok || outcome.result == null) {
      _handleWeatherError(outcome.status);
      setState(() => _useWeather = false);
      return;
    }

    final w = outcome.result!;
    setState(() {
      _weatherResult = w;
      _season = w.season;
      _useWeather = true;
    });
    final targetIndex = _seasons.keys.toList().indexOf(w.season);
    _seasonController.animateToItem(
      targetIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _handleWeatherError(WeatherStatus status) {
    String msg;
    bool showSettings = false;

    switch (status) {
      case WeatherStatus.serviceDisabled:
        msg = 'Konum servisi kapalı. Lütfen telefonun konumunu açın.';
        break;
      case WeatherStatus.deniedForever:
        msg = 'Konum izni kalıcı olarak reddedilmiş. Ayarlardan izin vermelisin.';
        showSettings = true;
        break;
      case WeatherStatus.denied:
        msg = 'Hava durumuna göre öneri için konum izni gerekli.';
        break;
      default:
        msg = 'Konum alınamadı. Lütfen tekrar dene.';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konum İzni'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          if (showSettings)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              child: const Text('Ayarları Aç'),
            ),
        ],
      ),
    );
  }

  late final FixedExtentScrollController _seasonController;
  late final FixedExtentScrollController _formalityController;

  final _seasons = const {
    'Summer': 'Yaz',
    'Winter': 'Kış',
    'MidSeason': 'Ara Mevsim',
  };
  final _formalities = const {
    'Loungewear': 'Ev',
    'Casual': 'Günlük',
    'SmartCasual': 'Smart',
    'Business': 'İş',
    'Formal': 'Resmi',
  };

  @override
  void initState() {
    super.initState();
    _seasonController = FixedExtentScrollController(
      initialItem: _seasons.keys.toList().indexOf(_season),
    );
    _formalityController = FixedExtentScrollController(
      initialItem: _formalities.keys.toList().indexOf(_formality),
    );
  }

  @override
  void dispose() {
    _seasonController.dispose();
    _formalityController.dispose();
    super.dispose();
  }

  Widget _prefToggle({
    required IconData icon,
    required String label,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: LuviaTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: enabled,
              onChanged: onToggle,
              activeColor: LuviaTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _prefChips(
    Map<String, String> options,
    String? selected,
    ValueChanged<String> onSelect,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final sel = e.key == selected;
        return ChoiceChip(
          label: Text(e.value),
          selected: sel,
          onSelected: (_) => onSelect(e.key),
          selectedColor: LuviaTheme.primary,
          labelStyle: TextStyle(
            color: sel ? Colors.white : Colors.black87,
            fontSize: 12,
          ),
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        children: [
          const Text(
            'Kombin Öner',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Kompakt hava toggle — tek satır
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 18,
                  color: LuviaTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _useWeather && _weatherResult != null
                        ? 'Hava: ${_weatherResult!.temp.round()}° · ${_seasons[_season]}'
                        : 'Hava durumunu kullan',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                _weatherLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LuviaTheme.primary,
                        ),
                      )
                    : Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: _useWeather,
                          onChanged: _toggleWeather,
                          
                          activeColor: LuviaTheme.primary,
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // İki dönme dolap yan yana
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Mevsim',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _wheelPicker(
                      controller: _seasonController,
                      map: _seasons,
                      selected: _season,
                      onChanged: _useWeather
                          ? null
                          : (v) => setState(() {
                              _season = v;
                              _onContextChanged();
                            }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Ortam',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _wheelPicker(
                      controller: _formalityController,
                      map: _formalities,
                      selected: _formality,
                      onChanged: (v) => setState(() {
                        _formality = v;
                        _onContextChanged();
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Renk toggle (isteğe bağlı)
          _prefToggle(
            icon: Icons.palette_outlined,
            label: 'Renk tercihi',
            enabled: _useColor,
            onToggle: (v) => setState(() {
              _useColor = v;
              _onContextChanged();
              if (!v)
                _selectedColor = null; // kapatınca temizle
              else
                _selectedColor ??= _colors.keys.first; // açınca varsayılan
            }),
          ),
          // Renk açıksa seçici göster
          if (_useColor) ...[
            const SizedBox(height: 8),
            _prefChips(
              _colors,
              _selectedColor,
              (v) => setState(() {
                _selectedColor = v;
                _onContextChanged();
              }),
            ),
          ],
          const SizedBox(height: 12),

          // Stil toggle (isteğe bağlı)
          _prefToggle(
            icon: Icons.style_outlined,
            label: 'Stil tercihi',
            enabled: _useStyle,
            onToggle: (v) => setState(() {
              _useStyle = v;
              _onContextChanged();
              if (!v)
                _selectedStyle = null;
              else
                _selectedStyle ??= _styles.keys.first;
            }),
          ),
          if (_useStyle) ...[
            const SizedBox(height: 8),
            _prefChips(
              _styles,
              _selectedStyle,
              (v) => setState(() {
                _selectedStyle = v;
                _onContextChanged();
              }),
            ),
          ],

          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_buttonLabel),
            style: FilledButton.styleFrom(
              backgroundColor: LuviaTheme.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_future != null) _results() else _emptyState(),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          // Yumuşak dairesel arka planlı ikon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  LuviaTheme.primary.withOpacity(0.15),
                  LuviaTheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 44,
              color: LuviaTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kombinin hazır olsun',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Mevsim ve ortamı seç,\ngardırobuna göre sana özel kombin oluşturalım.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Küçük ipucu rozetleri
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _hintChip(Icons.palette_outlined, 'Renk uyumu'),
              _hintChip(Icons.thermostat_outlined, 'Mevsime uygun'),
              _hintChip(Icons.check_circle_outline, 'Sana özel'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hintChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: LuviaTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _chips(
    Map<String, String> map,
    String selected,
    ValueChanged<String>? onSel,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: map.entries.map((e) {
        final sel = e.key == selected;
        final locked = onSel == null; // kilitli mi?
        return ChoiceChip(
          label: Text(e.value),
          selected: sel,
          onSelected: locked
              ? null
              : (_) => onSel(e.key), // kilitliyse tıklanamaz
          selectedColor: LuviaTheme.primary,
          labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
          backgroundColor: Colors.white,
          disabledColor: sel
              ? LuviaTheme.primary.withOpacity(0.6)
              : Colors.grey.shade200,
        );
      }).toList(),
    );
  }

  Widget _results() {
    return FutureBuilder<OutfitResult>(
      // ← OutfitResult
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }

        final result = snap.data;
        if (result == null) return const SizedBox();

        // Eksik mesajı varsa — kombin yerine onu göster
        if (result?.missingMessage != null)
          return _missingCard(result!.missingMessage!);

        final outfits = result?.outfits ?? [];
        if (outfits.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Bu bağlama uygun kombin bulunamadı.'),
            ),
          );
        }

        // Kombinleri göster (mevcut kart mantığın)
        return Column(children: outfits.map((o) => _outfitCard(o)).toList());
      },
    );
  }

  Widget _missingCard(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuviaTheme.bgTop,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: LuviaTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheelPicker({
    required FixedExtentScrollController controller, // ← dışarıdan
    required Map<String, String> map,
    required String selected,
    required ValueChanged<String>? onChanged,
  }) {
    final keys = map.keys.toList();
    final locked = onChanged == null;

    return SizedBox(
      height: 120,
      child: ListWheelScrollView.useDelegate(
        controller: controller, // ← state'teki controller
        itemExtent: 44,
        perspective: 0.004,
        diameterRatio: 1.4,
        physics: locked
            ? const NeverScrollableScrollPhysics()
            : const FixedExtentScrollPhysics(),
        onSelectedItemChanged: locked ? null : (i) => onChanged(keys[i]),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: keys.length,
          builder: (context, i) {
            final sel = keys[i] == selected;
            return Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: sel ? 22 : 16,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  color: sel
                      ? (locked
                            ? LuviaTheme.primary.withOpacity(0.5)
                            : LuviaTheme.primary)
                      : Colors.black38,
                ),
                child: Text(map[keys[i]]!),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _outfitCard(Outfit o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: LuviaTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Uyum %${(o.score * 100).round()}',
                  style: const TextStyle(
                    color: LuviaTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: o.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = o.items[i];
                return SizedBox(
                  width: 80, // sabit genişlik — daralmaz
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            color: LuviaTheme.bgTop,
                            borderRadius: BorderRadius.circular(14),
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
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.color} ${item.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (o.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: o.reasons
                  .map(
                    (r) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: LuviaTheme.bgTop,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
