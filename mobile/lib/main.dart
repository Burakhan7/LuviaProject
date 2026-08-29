// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/outfits_screen.dart';
import 'screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen.dart';
import 'screens/studio_screen.dart';
import 'services/api_service.dart';
import 'models/wardrobe_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LuviaApp());
}

class LuviaApp extends StatelessWidget {
  const LuviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luvia',
      debugShowCheckedModeBanner: false,
      theme: LuviaTheme.theme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Kullanıcı yoksa (ilk açılış) → arka planda anonim giriş yap
          if (!snapshot.hasData) {
            FirebaseAuth.instance.signInAnonymously();
            // Anonim giriş tamamlanana kadar kısa bir yükleme göster
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Kullanıcı var (anonim veya gerçek) → direkt içeri
          return const MainShell();
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _emptyWarnCount = 0; // oturum sayacı — galeri boşken en fazla 2 kez uyar
  bool _galleryEmpty = true; // galeri boş mu (kıyafet yok mu)
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _refreshGalleryStatus();
  }

  // Galeri boş mu — API'den kıyafet sayısını çekip günceller
  Future<void> _refreshGalleryStatus() async {
    try {
      final items = await _api.getWardrobe();
      if (mounted) setState(() => _galleryEmpty = items.isEmpty);
    } catch (_) {
      // sessiz — hata olursa galeri durumu değişmez
    }
  } // kıyafet sayısını kontrol için

  final _homeKey = GlobalKey<HomeScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();
  final _wardrobeKey = GlobalKey<WardrobeScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey, onNavigateToTab: _goToTab), // index 0
    WardrobeScreen(key: _wardrobeKey), // index 1
    const OutfitsScreen(), // index 2
    const StudioScreen(), // index 3 — Oluştur
    ProfileScreen(key: _profileKey),
  ];

  void _goToTab(int i) {
    setState(() => _index = i);
  }

  void _onTabChanged(int i) {
    // Galeri boş + galeriden BAŞKA sekmeye gidiyor + henüz 2 kez uyarmadıysak
    if (_galleryEmpty && i != 1 && _emptyWarnCount < 2) {
      _emptyWarnCount++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bir kıyafet ekleyelim mi? 👕'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() => _index = i);
    if (i == 0) _homeKey.currentState?.refresh();
    if (i == 1) {
      _refreshGalleryStatus();
      _wardrobeKey.currentState?.checkCameraTutorial();
    }
    if (i == 3) _profileKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LuviaTheme.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTabChanged,
          backgroundColor: Colors.white,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Galeri',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Kombin',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(Icons.add_box),
              label: 'Oluştur',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
