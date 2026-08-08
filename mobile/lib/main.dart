// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile/firebase_options.dart';
import 'models/wardrobe_item.dart';
import 'services/api_service.dart';

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
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const WardrobeScreen(),
    );
  }
}

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final _api = ApiService();
  late Future<List<WardrobeItem>> _wardrobeFuture;

  @override
  void initState() {
    super.initState();
    _wardrobeFuture = _api.getWardrobe();
  }

  void _refresh() {
    setState(() => _wardrobeFuture = _api.getWardrobe());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gardırobum'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<WardrobeItem>>(
        future: _wardrobeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Gardırop boş. Kıyafet ekle!'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return ListTile(
                leading: item.processedImageUrl != null
                    ? Image.network(
                        item.processedImageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.checkroom),
                      )
                    : const Icon(Icons.checkroom),
                title: Text('${item.color} ${item.category}'),
                subtitle: Text(
                  '${item.kind}${item.style != null ? " · ${item.style}" : ""}'
                  '${item.isLayered ? " · katmanlı" : ""}',
                ),
                trailing: item.needsReview
                    ? const Icon(Icons.help_outline, color: Colors.orange)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
