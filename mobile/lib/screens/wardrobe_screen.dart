import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _api = ApiService();
  final _storage = StorageService();
  late Future<List<WardrobeItem>> _future;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getWardrobe();
  }

  void _refresh() => setState(() => _future = _api.getWardrobe());

  Future<void> _add({required bool fullbody}) async {
    try {
      setState(() => _uploading = true);
      final url = await _storage.pickAndUpload();
      if (url == null) {
        setState(() => _uploading = false);
        return;
      }
      fullbody ? await _api.addFullbody(url) : await _api.addItem(url);
      _refresh();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Eklendi!')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showAddSheet() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.checkroom, color: LuviaTheme.primary),
            title: const Text('Parça Ekle'),
            subtitle: const Text('Tek kıyafetin fotoğrafı'),
            onTap: () {
              Navigator.pop(context);
              _add(fullbody: false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: LuviaTheme.primary),
            title: const Text('Kombin Yakala'),
            subtitle: const Text('Boydan fotoğraf'),
            onTap: () {
              Navigator.pop(context);
              _add(fullbody: true);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _uploading
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _showAddSheet,
              child: const Icon(Icons.add_a_photo),
            ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gardırobum',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<WardrobeItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (snap.hasError)
                    return Center(child: Text('Hata: ${snap.error}'));
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Gardırop boş. + ile kıyafet ekle!',
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Container(
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
                                        size: 40,
                                        color: LuviaTheme.primary,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.color} ${item.category}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    item.isLayered
                                        ? '${item.kind} · katmanlı'
                                        : item.kind,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
