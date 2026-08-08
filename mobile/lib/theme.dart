import 'package:flutter/material.dart';

class LuviaTheme {
  static const Color primary = Color(0xFF7B4DFF);
  static const Color primaryDark = Color(0xFF5E35D9);
  static const Color bgTop = Color(0xFFF4EEFF);
  static const Color bgBottom = Colors.white;

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary),
    scaffoldBackgroundColor: Colors.transparent,
  );

  static const BoxDecoration bg = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bgTop, bgBottom],
    ),
  );
}
