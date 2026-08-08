// lib/screens/outfits_screen.dart
import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../services/api_service.dart';
import '../theme.dart';

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});
  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  final _api = ApiService();
  Future<List<Outfit>>? _future;

  String _season = 'MidSeason';
  String _formality = 'Casual';

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

  void _generate() {
    setState(() {
      _future = _api.getOutfits(
        _season,
        _formality,
      ); // await YOK — sadece Future'ı ata
    });
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
          const SizedBox(height: 4),
          const Text(
            'Bağlamı seç, sana özel kombin oluşturalım',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),

          const Text('Mevsim', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _chips(_seasons, _season, (v) => setState(() => _season = v)),
          const SizedBox(height: 16),

          const Text('Ortam', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _chips(
            _formalities,
            _formality,
            (v) => setState(() => _formality = v),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Kombin Oluştur'),
            style: FilledButton.styleFrom(
              backgroundColor: LuviaTheme.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_future != null) _results(),
        ],
      ),
    );
  }

  Widget _chips(
    Map<String, String> map,
    String selected,
    ValueChanged<String> onSel,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: map.entries.map((e) {
        final sel = e.key == selected;
        return ChoiceChip(
          label: Text(e.value),
          selected: sel,
          onSelected: (_) => onSel(e.key),
          selectedColor: LuviaTheme.primary,
          labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _results() {
    return FutureBuilder<List<Outfit>>(
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
        if (snap.hasError) return Center(child: Text('Hata: ${snap.error}'));
        final outfits = snap.data ?? [];
        if (outfits.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.sentiment_dissatisfied,
                  size: 40,
                  color: Colors.black26,
                ),
                SizedBox(height: 8),
                Text(
                  'Bu bağlama uygun kombin bulunamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Daha fazla kıyafet ekle ya da bağlamı değiştir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          );
        }
        return Column(children: outfits.map(_outfitCard).toList());
      },
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
          const SizedBox(height: 12),
          Row(
            children: o.items
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: LuviaTheme.bgTop,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item.processedImageUrl != null
                                  ? Image.network(
                                      item.processedImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.checkroom,
                                        color: LuviaTheme.primary,
                                      ),
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
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
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
