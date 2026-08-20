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

// ── Yaklaşım C: Collage/Grid kart ──
class OutfitCardGrid extends StatelessWidget {
  final List<WardrobeItem> items;
  final bool showBackground;
  const OutfitCardGrid({
    super.key,
    required this.items,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final display = items.take(4).toList();

    final layout = Padding(
      padding: EdgeInsets.all(showBackground ? 16 : 0),
      child: _buildLayout(display),
    );

    if (!showBackground) return layout;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: layout,
    );
  }

  Widget _buildLayout(List<WardrobeItem> items) {
    // 3 item: 2 üstte + 1 ortada altta (ayakkabı merkezde)
    if (items.length == 3) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _gridItem(items[0]),
              const SizedBox(width: 8),
              _gridItem(items[1]),
            ],
          ),
          const SizedBox(height: 8),
          _gridItem(items[2]), // altta ortalı
        ],
      );
    }

    // 4 item: 2x2
    if (items.length == 4) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _gridItem(items[0]),
              const SizedBox(width: 8),
              _gridItem(items[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _gridItem(items[2]),
              const SizedBox(width: 8),
              _gridItem(items[3]),
            ],
          ),
        ],
      );
    }

    // 2 item: yan yana
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: items
          .map(
            (it) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _gridItem(it),
            ),
          )
          .toList(),
    );
  }

  Widget _gridItem(WardrobeItem it) {
    return SizedBox(
      width: 100, // item boyutu (koruduk)
      height: 100,
      child: it.processedImageUrl != null
          ? CachedNetworkImage(
              imageUrl: it.processedImageUrl!,
              fit: BoxFit.contain,
              memCacheWidth: 300,
              placeholder: (c, u) => const SizedBox.shrink(),
              errorWidget: (c, u, e) => const Icon(Icons.checkroom),
            )
          : const Icon(Icons.checkroom),
    );
  }
}
