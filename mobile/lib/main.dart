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
          // Giriş yapmışsa ana uygulama, yapmamışsa giriş ekranı
          return snapshot.hasData ? const MainShell() : const AuthScreen();
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

  final _homeKey = GlobalKey<HomeScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey, onNavigateToTab: _goToTab), // index 0
    const WardrobeScreen(), // index 1
    const OutfitsScreen(), // index 2
    ProfileScreen(key: _profileKey),
  ];

  void _goToTab(int i) {
    setState(() => _index = i);
  }

  void _onTabChanged(int i) {
    setState(() => _index = i);
    if (i == 0) {
      _homeKey.currentState?.refresh();
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
