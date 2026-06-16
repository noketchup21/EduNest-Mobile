import 'package:flutter/material.dart';

class AppTheme {
  static const _fontFallback = [
    'Roboto',
    'Noto Sans',
    'Arial',
    'Segoe UI',
    'sans-serif',
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamilyFallback: _fontFallback,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF60A5FA), brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamilyFallback: _fontFallback,
    );
  }
}
