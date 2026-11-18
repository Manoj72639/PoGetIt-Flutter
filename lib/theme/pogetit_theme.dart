import 'package:flutter/material.dart';

class PoGetItTheme {
  static const black = Color(0xFF111111);
  static const gray = Color(0xFF666666);
  static const canvas = Color(0xFFF7F7F7);
  static const border = Color(0xFFE5E5E5);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: black,
      brightness: Brightness.light,
      primary: black,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: black,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: black,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFECECEC),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: black,
          ),
        ),
      ),
    );
  }
}
