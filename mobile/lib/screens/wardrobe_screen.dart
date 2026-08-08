import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  String _selectedFilter = 'Tümü';

  static const _upperCats = {
    'TShirt', 'Shirt', 'Sweater', 'Hoodie', 'Cardigan', 'Jacket', 'Coat', 'Blazer',
  };
  static const _lowerCats = {'Jeans', 'Pants', 'Shorts', 'Skirt', 'Sweatpants'};

  @override
  void initState() {
    super.initState();
    _future = _api.getWardrobe();
  }

  void _refresh() {
    setState(() {
      _future = _api.getWardrobe();
    });
  }

  Future<void> _toggleAvailability(WardrobeItem item) async {
    try {
      await _api.setAvailability(item.id, !item.isAvailable);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _confirmDelete(WardrobeItem item) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil'),
              subtitle: Text('${item.color} ${item.category}'),
              onTap: () {
                Navigator.pop(context);
                _deleteItem(item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(WardrobeItem item) async {
    try {
      await _api.deleteItem(item.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Silindi')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  bool _matchesFilter(WardrobeItem item) {
    switch (_selectedFilter) {
      case 'Tümü':
        return true;
      case 'Üst':
        return item.kind == 'Clothing' && _upperCats.contains(item.category);
      case 'Alt':
        return item.kind == 'Clothing' && _lowerCats.contains(item.category);
      case 'Elbise':
        return item.category == 'Dress';
      case 'Ayakkabı':
        return item.kind == 'Shoes';
      case 'Aksesuar':
        return item.kind == 'Accessory';
      case 'Takı':
        return item.kind == 'Jewelry';
      default:
        return true;
    }
  }

    Future<void> _add({required bool fullbody, required ImageSource source}) async {
    try {
      setState(() { _uploading = true; });

      final url = await _storage.pickAndUpload(source: source);   // ← source geçir
      if (url == null) {
        setState(() { _uploading = false; });
        return;
      }

      if (fullbody) {
        await _api.addFullbody(url);
      } else {
        await _api.addItem(url);
      }

      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Eklendi!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() { _uploading = false; });
    }
  }

    void _showAddSheet() => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _addRow(
                  icon: Icons.checkroom,
                  title: 'Parça Ekle',
                  subtitle: 'Tek kıyafetin fotoğrafı',
                  fullbody: false,
                ),
                const Divider(height: 28),
                _addRow(
                  icon: Icons.person,
                  title: 'Kombin Yakala',
                  subtitle: 'Boydan fotoğraf',
                  fullbody: true,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _addRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool fullbody,
  }) {
    return Row(
      children: [
        Icon(icon, color: LuviaTheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        // Kamera butonu
        IconButton(
          onPressed: () {
            Navigator.pop(context);
            _add(fullbody: fullbody, source: ImageSource.camera);
          },
          icon: const Icon(Icons.camera_alt),
          color: LuviaTheme.primary,
          tooltip: 'Çek',
          style: IconButton.styleFrom(backgroundColor: LuviaTheme.bgTop),
        ),
        const SizedBox(width: 8),
        // Galeri butonu
        IconButton(
          onPressed: () {
            Navigator.pop(context);
            _add(fullbody: fullbody, source: ImageSource.gallery);
          },
          icon: const Icon(Icons.photo_library),
          color: LuviaTheme.primary,
          tooltip: 'Galeri',
          style: IconButton.styleFrom(backgroundColor: LuviaTheme.bgTop),
        ),
      ],
    );
  }

  Widget _filterBar() {
    const filters = ['Tümü', 'Üst', 'Alt', 'Elbise', 'Ayakkabı', 'Aksesuar', 'Takı'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final sel = f == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: sel ? LuviaTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                ],
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
                  IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
                ],
              ),
            ),
            _filterBar(),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<WardrobeItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Hata: ${snap.error}'));
                  }

                  final all = snap.data ?? [];
                  final items = all.where(_matchesFilter).toList();

                  if (all.isEmpty) {
                    return const Center(
                      child: Text('Gardırop boş. + ile kıyafet ekle!',
                          style: TextStyle(color: Colors.black54)),
                    );
                  }
                  if (items.isEmpty) {
                    return Center(
                      child: Text('"$_selectedFilter" kategorisinde parça yok',
                          style: const TextStyle(color: Colors.black54)),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return GestureDetector(
                        onDoubleTap: () => _toggleAvailability(item),
                        onLongPress: () => _confirmDelete(item),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: item.isAvailable ? 1.0 : 0.4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10),
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
                                              filterQuality: FilterQuality.medium,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.checkroom),
                                            )
                                          : Container(
                                              color: LuviaTheme.bgTop,
                                              child: const Icon(Icons.checkroom,
                                                  size: 30,
                                                  color: LuviaTheme.primary),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${item.color} ${item.category}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600)),
                                          Text(
                                              item.isLayered
                                                  ? '${item.kind} · katmanlı'
                                                  : item.kind,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.black54)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!item.isAvailable)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Müsait değil',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 8)),
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