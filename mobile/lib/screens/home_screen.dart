import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../services/api_service.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  late Future<List<WardrobeItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getWardrobe();
  }

  void refresh() {
    setState(() {
      _future = _api.getWardrobe();
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<WardrobeItem>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
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
              const SizedBox(height: 20),
              Text(
                _greeting,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const Text(
                'Bugün ne giysek?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _heroCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _stat('${items.length}', 'Parça', Icons.checkroom),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _stat('0', 'Kombin', Icons.favorite_border)),
                ],
              ),
              const SizedBox(height: 28),
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

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(24),
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
        const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
        const SizedBox(height: 12),
        const Text(
          'Bugünün Kombini',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gardırobuna göre sana özel öneri',
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: LuviaTheme.primary,
          ),
          child: const Text('Kombin Oluştur'),
        ),
      ],
    ),
  );

  Widget _stat(String value, String label, IconData icon) => Container(
    padding: const EdgeInsets.all(18),
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
        Icon(icon, color: LuviaTheme.primary),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );

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
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.checkroom, size: 40, color: Colors.black26),
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
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length > 10 ? 10 : items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
                      ? Image.network(
                          item.processedImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
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
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${item.color} ${item.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
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
