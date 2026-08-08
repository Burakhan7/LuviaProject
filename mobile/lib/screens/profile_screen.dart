// profile_screen.dart
import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundColor: LuviaTheme.primary,
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'burak',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Test kullanıcısı',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}
