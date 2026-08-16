import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../services/api_service.dart';
import '../theme.dart';

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final _api = ApiService();

  // Merkez çarklar için seçili index (ortadaki)
  int _upperIndex = 0;
  int _lowerIndex = 0;
  int _shoesIndex = 0;

  // Yan kartlar (Tasarım B — tıkla seç)
  WardrobeItem? _accessory;
  WardrobeItem? _jewelry;

  List<WardrobeItem> _wardrobe = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWardrobe();
  }

  Future<void> _loadWardrobe() async {
    try {
      final items = await _api.getWardrobe();
      if (mounted) {
        setState(() {
          _wardrobe = items.where((i) => i.isAvailable).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _upperCats = {
    'TShirt',
    'Shirt',
    'Sweater',
    'Hoodie',
    'Cardigan',
    'Jacket',
    'Coat',
    'Blazer',
  };
  static const _lowerCats = {'Jeans', 'Pants', 'Shorts', 'Skirt', 'Sweatpants'};

  List<WardrobeItem> _itemsFor(String slot) {
    switch (slot) {
      case 'Üst':
        return _wardrobe
            .where(
              (i) => i.kind == 'Clothing' && _upperCats.contains(i.category),
            )
            .toList();
      case 'Alt':
        return _wardrobe
            .where(
              (i) => i.kind == 'Clothing' && _lowerCats.contains(i.category),
            )
            .toList();
      case 'Ayakkabı':
        return _wardrobe.where((i) => i.kind == 'Shoes').toList();
      case 'Aksesuar':
        return _wardrobe.where((i) => i.kind == 'Accessory').toList();
      case 'Takı':
        return _wardrobe.where((i) => i.kind == 'Jewelry').toList();
      default:
        return [];
    }
  }

  // ── Yan kart seçici (Tasarım B — bottom sheet) ──
  Future<void> _pickSide(String slot) async {
    final items = _itemsFor(slot);
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$slot kategorisinde parça yok.')));
      return;
    }

    final selected = await showModalBottomSheet<WardrobeItem>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$slot seç',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: LuviaTheme.bgTop,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: item.processedImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.processedImageUrl!,
                                fit: BoxFit.cover,
                                memCacheWidth: 200,
                              )
                            : const Icon(Icons.checkroom),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        if (slot == 'Aksesuar') _accessory = selected;
        if (slot == 'Takı') _jewelry = selected;
      });
    }
  }

  bool _evaluating = false;

  Future<void> _evaluate() async {
    // Çarkların ortasındaki (seçili) item'ları al
    final upperItems = _itemsFor('Üst');
    final lowerItems = _itemsFor('Alt');
    final shoesItems = _itemsFor('Ayakkabı');

    final upper = upperItems.isNotEmpty ? upperItems[_upperIndex] : null;
    final lower = lowerItems.isNotEmpty ? lowerItems[_lowerIndex] : null;
    final shoes = shoesItems.isNotEmpty ? shoesItems[_shoesIndex] : null;

    // Seçili tüm item ID'lerini topla (null olanları atla)
    final ids = <String>[];
    if (upper != null) ids.add(upper.id);
    if (lower != null) ids.add(lower.id);
    if (shoes != null) ids.add(shoes.id);
    if (_accessory != null) ids.add(_accessory!.id);
    if (_jewelry != null) ids.add(_jewelry!.id);

    if (ids.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Değerlendirme için en az 2 parça seçili olmalı.'),
        ),
      );
      return;
    }

    setState(() => _evaluating = true);
    try {
      final result = await _api.evaluateOutfit(ids, 'MidSeason');
      if (!mounted) return;
      _showResult(result.score, result.comments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Değerlendirme yapılamadı: $e')));
      }
    } finally {
      if (mounted) setState(() => _evaluating = false);
    }
  }

  void _showResult(int score, List<String> comments) {
    // Skora göre renk ve başlık
    Color scoreColor;
    String title;
    if (score >= 80) {
      scoreColor = Colors.green;
      title = 'Harika kombin!';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      title = 'Fena değil';
    } else {
      scoreColor = Colors.red;
      title = 'Geliştirilebilir';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skor dairesi
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Yorumlar
              ...comments.map(
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: LuviaTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: LuviaTheme.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kombin Stüdyosu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Yan kartlar — Aksesuar (sol) / Takı (sağ)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sideCard('Aksesuar', _accessory),
                  _sideCard('Takı', _jewelry),
                ],
              ),
            ),

            // Merkez çarklar — Üst / Alt / Ayakkabı
            // Merkez çarklar — Üst / Alt / Ayakkabı (statik, dikey scroll yok)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _carousel(
                      'Üst',
                      _upperIndex,
                      (i) => setState(() => _upperIndex = i),
                    ),
                  ),
                  Expanded(
                    child: _carousel(
                      'Alt',
                      _lowerIndex,
                      (i) => setState(() => _lowerIndex = i),
                    ),
                  ),
                  Expanded(
                    child: _carousel(
                      'Ayakkabı',
                      _shoesIndex,
                      (i) => setState(() => _shoesIndex = i),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _evaluating ? null : _evaluate,
                  style: FilledButton.styleFrom(
                    backgroundColor: LuviaTheme.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _evaluating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Değerlendir'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Merkez çark (PageView, ortadaki net, yanlar yarı saydam) ──
  Widget _carousel(String slot, int currentIndex, ValueChanged<int> onChanged) {
    final items = _itemsFor(slot);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 4),
            child: Text(
              slot,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Bu kategoride parça yok',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : _CarouselRow(
                    key: ValueKey('$slot-${items.length}'),
                    items: items,
                    onIndexChanged: onChanged,
                  ),
          ),
        ],
      ),
    );
  }

  // Yan kart (Tasarım B)
  Widget _sideCard(String label, WardrobeItem? item) {
    return GestureDetector(
      onTap: () => _pickSide(label),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: item == null ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: LuviaTheme.primary.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: item == null
            ? Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: LuviaTheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  item.processedImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.processedImageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 150,
                        )
                      : const Icon(Icons.checkroom),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (label == 'Aksesuar') _accessory = null;
                        if (label == 'Takı') _jewelry = null;
                      }),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Ayrı widget: yatay çark satırı ──
class _CarouselRow extends StatefulWidget {
  final List<WardrobeItem> items;
  final ValueChanged<int> onIndexChanged;
  const _CarouselRow({
    super.key,
    required this.items,
    required this.onIndexChanged,
  });

  @override
  State<_CarouselRow> createState() => _CarouselRowState();
}

class _CarouselRowState extends State<_CarouselRow> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.32);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.items.length,
      onPageChanged: (i) {
        setState(() => _current = i);
        widget.onIndexChanged(i);
      },
      itemBuilder: (context, i) {
        final item = widget.items[i];
        final isCenter = i == _current;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isCenter ? 1.0 : 0.4,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isCenter ? 1.0 : 0.8,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCenter ? LuviaTheme.primary : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: item.processedImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.processedImageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      placeholder: (c, u) => Container(color: LuviaTheme.bgTop),
                      errorWidget: (c, u, e) => const Icon(Icons.checkroom),
                    )
                  : Container(
                      color: LuviaTheme.bgTop,
                      child: const Icon(Icons.checkroom),
                    ),
            ),
          ),
        );
      },
    );
  }
}
