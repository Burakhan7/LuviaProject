import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../theme.dart';

class OutfitCard extends StatelessWidget {
  final List<WardrobeItem> items;
  const OutfitCard({super.key, required this.items});

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

  @override
  Widget build(BuildContext context) {
    WardrobeItem? upper, lower, dress, shoes, accessory, jewelry;
    for (final it in items) {
      if (it.kind == 'Clothing' && it.category == 'Dress') {
        dress = it;
      } else if (it.kind == 'Clothing' && _upperCats.contains(it.category)) {
        upper ??= it;
      } else if (it.kind == 'Clothing' && _lowerCats.contains(it.category)) {
        lower ??= it;
      } else if (it.kind == 'Shoes') {
        shoes ??= it;
      } else if (it.kind == 'Accessory') {
        accessory ??= it;
      } else if (it.kind == 'Jewelry') {
        jewelry ??= it;
      }
    }

    final axis = <WardrobeItem>[];
    if (dress != null) {
      axis.add(dress);
    } else {
      if (upper != null) axis.add(upper);
      if (lower != null) axis.add(lower);
    }
    if (shoes != null) axis.add(shoes);

    final sideItems = <WardrobeItem>[
      if (accessory != null) accessory,
      if (jewelry != null) jewelry,
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.20),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _AxisStack(items: axis)),
          if (sideItems.isNotEmpty) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: sideItems
                  .map(
                    (it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _boxImage(it, 52, 12),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _boxImage(WardrobeItem it, double size, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: it.processedImageUrl != null
          ? CachedNetworkImage(
              imageUrl: it.processedImageUrl!,
              fit: BoxFit.contain,
              memCacheWidth: 300,
              placeholder: (c, u) => Container(color: LuviaTheme.bgTop),
              errorWidget: (c, u, e) => const Icon(Icons.checkroom),
            )
          : Container(
              color: LuviaTheme.bgTop,
              child: const Icon(Icons.checkroom),
            ),
    );
  }
}

class _AxisStack extends StatelessWidget {
  final List<WardrobeItem> items;
  const _AxisStack({required this.items});

  @override
  Widget build(BuildContext context) {
    const itemSize = 110.0;
    const overlap = 20.0;

    final totalHeight = items.isEmpty
        ? 0.0
        : itemSize + (items.length - 1) * (itemSize - overlap);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < items.length; i++)
            Positioned(
              top: i * (itemSize - overlap),
              child: _layeredItem(items[i], itemSize),
            ),
        ],
      ),
    );
  }

  Widget _layeredItem(WardrobeItem it, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: it.processedImageUrl != null
          ? CachedNetworkImage(
              imageUrl: it.processedImageUrl!,
              fit: BoxFit.contain,
              memCacheWidth: 300,
              placeholder: (c, u) => Container(color: LuviaTheme.bgTop),
              errorWidget: (c, u, e) => const Icon(Icons.checkroom),
            )
          : Container(
              color: LuviaTheme.bgTop,
              child: const Icon(Icons.checkroom),
            ),
    );
  }
}

class OutfitCardGrid extends StatelessWidget {
  final List<WardrobeItem> items;
  final bool showBackground;

  const OutfitCardGrid({
    super.key,
    required this.items,
    this.showBackground = true,
  });

  List<int> _rowCounts(int n) {
    switch (n) {
      case 1:
        return [1];
      case 2:
        return [2];
      case 3:
        return [3]; // 3 öğeyi tek satıra alarak daha simetrik ve büyük gösterir
      case 4:
        return [2, 2];
      case 5:
        return [3, 2];
      case 6:
        return [3, 3];
      default:
        return [3, 3];
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = items.take(6).toList();
    if (display.isEmpty) return const SizedBox.shrink();

    final rows = _rowCounts(display.length);
    final maxCols = rows.reduce((a, b) => a > b ? a : b);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        // Mevcut alan (iç padding'ler düşülmüş hali)
        final w = constraints.maxWidth;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : w;

        const double gap = 12.0;

        // Yatay ve dikey kısıtlamalara göre ulaşılabilecek maksimum kare kenarı
        final cellW = (w - (maxCols - 1) * gap) / maxCols;
        final cellH = (h - (rows.length - 1) * gap) / rows.length;
        final cellSize = (cellW < cellH ? cellW : cellH).clamp(40.0, 160.0);

        int idx = 0;
        final rowWidgets = <Widget>[];

        for (int r = 0; r < rows.length; r++) {
          final count = rows[r];
          final cells = <Widget>[];

          for (int c = 0; c < count; c++) {
            if (idx >= display.length) break;
            final it = display[idx++];

            cells.add(
              SizedBox(
                width: cellSize,
                height: cellSize,
                child: it.processedImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: it.processedImageUrl!,
                        fit: BoxFit.contain,
                        memCacheWidth: 400,
                        placeholder: (c, u) => const SizedBox.shrink(),
                        errorWidget: (c, u, e) =>
                            const Icon(Icons.checkroom, size: 36),
                      )
                    : const Icon(Icons.checkroom, size: 36),
              ),
            );
          }

          rowWidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: cells,
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rowWidgets,
          ),
        );
      },
    );

    if (!showBackground) return content;

    return Container(
      width: double
          .infinity, // Kartın yatayda mor alanın tamamına yayılmasını sağlar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: content,
    );
  }
}
