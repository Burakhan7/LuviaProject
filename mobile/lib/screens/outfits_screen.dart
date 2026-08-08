// outfits_screen.dart
import 'package:flutter/material.dart';

class OutfitsScreen extends StatelessWidget {
  const OutfitsScreen({super.key});
  @override
  Widget build(BuildContext context) => const SafeArea(
    child: Center(
      child: Text(
        'Kombin önerileri yakında',
        style: TextStyle(color: Colors.black54),
      ),
    ),
  );
}
