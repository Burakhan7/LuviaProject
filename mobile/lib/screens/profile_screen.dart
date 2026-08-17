import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wardrobe_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _auth = AuthService();
  late Future<List<WardrobeItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getWardrobe();
  }

  void refresh() {
    // ← ekle
    setState(() {
      _future = _api.getWardrobe();
    });
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      // authStateChanges otomatik AuthScreen'e döndürür
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hesabımı Sil'),
        content: const Text(
          'Hesabın ve tüm kıyafetlerin kalıcı olarak silinecek. '
          'Bu işlem geri alınamaz. Devam etmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hesabımı Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Yükleme göstergesi
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // 1. Önce DB verilerini sil (userId hâlâ geçerliyken)
      await _api.deleteAccountData();
      // 2. Sonra Firebase Auth hesabını sil
      final error = await _auth.deleteAccount();

      if (!mounted) return;
      Navigator.pop(context); // yükleme dialogunu kapat

      if (error == 'requires-recent-login') {
        // Güvenlik: yeniden giriş gerekli
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Güvenlik için çıkış yapıp tekrar giriş yaptıktan sonra hesabını silebilirsin.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      // Başarılı — authStateChanges otomatik başlangıca döndürür (anonim giriş yeniden başlar)
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // yükleme dialogunu kapat
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hesap silinemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Kullanıcı';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return SafeArea(
      child: FutureBuilder<List<WardrobeItem>>(
        future: _future,
        builder: (context, snap) {
          final items = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Başlık
              const Text(
                'Profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Kimlik kartı
              Container(
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: LuviaTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${items.length} parça · Luvia üyesi',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gardırop istatistikleri
              const Text(
                'Gardırobun',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _statsGrid(items),
              const SizedBox(height: 24),

              // Renk paleti
              if (items.isNotEmpty) ...[
                const Text(
                  'Renk Paletin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _colorPalette(items),
                const SizedBox(height: 24),
              ],

              // Gardırop karnesi (öneri)
              _wardrobeAdvice(items),
              const SizedBox(height: 24),

              // Çıkış
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 20,
                  ),
                  label: const Text(
                    'Hesabımı Sil',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Luvia v1.0',
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statsGrid(List<WardrobeItem> items) {
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
    final elbise = items.where((i) => i.category == 'Dress').length;
    final ayakkabi = items.where((i) => i.kind == 'Shoes').length;
    final aksesuar = items.where((i) => i.kind == 'Accessory').length;
    final taki = items.where((i) => i.kind == 'Jewelry').length;

    final stats = [
      ('Üst', ust, Icons.checkroom),
      ('Alt', alt, Icons.dry_cleaning),
      ('Elbise', elbise, Icons.woman),
      ('Ayakkabı', ayakkabi, Icons.ice_skating),
      ('Aksesuar', aksesuar, Icons.watch),
      ('Takı', taki, Icons.diamond),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: stats
          .map(
            (s) => Container(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s.$3, color: LuviaTheme.primary, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    '${s.$2}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    s.$1,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _colorPalette(List<WardrobeItem> items) {
    // Renk sayımı
    final counts = <String, int>{};
    for (final i in items) {
      counts[i.color] = (counts[i.color] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: top
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _colorFor(e.key),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.key} (${e.value})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // Renk ismini yaklaşık bir Color'a çevir (görsel için)
  Color _colorFor(String name) {
    const map = {
      'Black': Color(0xFF1A1A1A),
      'White': Color(0xFFF5F5F5),
      'Gray': Color(0xFF9E9E9E),
      'Navy': Color(0xFF1A237E),
      'Blue': Color(0xFF2196F3),
      'Red': Color(0xFFE53935),
      'Green': Color(0xFF43A047),
      'Yellow': Color(0xFFFDD835),
      'Beige': Color(0xFFD7CCC8),
      'Brown': Color(0xFF6D4C41),
      'Pink': Color(0xFFEC407A),
      'Purple': Color(0xFF8E24AA),
      'Orange': Color(0xFFFB8C00),
      'Cream': Color(0xFFFFF8E1),
      'RoseGold': Color(0xFFB76E79),
    };
    return map[name] ?? Colors.grey;
  }

  Widget _wardrobeAdvice(List<WardrobeItem> items) {
    String advice;
    IconData icon;

    if (items.isEmpty) {
      advice =
          'Gardırobun boş. Birkaç kıyafet ekle, kombin önerileri başlasın!';
      icon = Icons.add_circle_outline;
    } else {
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

      if (ust == 0) {
        advice =
            'Hiç üst giyimin yok. Birkaç tişört ya da gömlek ekle, kombinler oluşsun.';
        icon = Icons.checkroom;
      } else if (alt == 0) {
        advice =
            'Alt giyimin yok. Pantolon ya da etek ekleyince kombin çeşitliliğin artar.';
        icon = Icons.dry_cleaning;
      } else if (ayakkabi == 0) {
        advice = 'Ayakkabın yok. Bir çift ekle, kombinlerin tamamlansın.';
        icon = Icons.ice_skating;
      } else if (ust < alt * 2) {
        advice = 'Daha fazla üst giyim eklersen kombin seçeneklerin katlanır.';
        icon = Icons.auto_awesome;
      } else {
        advice =
            'Gardırobun dengeli görünüyor! Farklı renkler ekleyerek çeşitliliği artırabilirsin.';
        icon = Icons.check_circle_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuviaTheme.bgTop,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: LuviaTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              advice,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
