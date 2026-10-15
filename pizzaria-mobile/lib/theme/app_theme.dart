import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFFD62828);
  static const primaryPressed = Color(0xFFAD2020);
  static const accent = Color(0xFFF4A261);
  static const surface = Color(0xFFFFF8F2);
  static const textPrimary = Color(0xFF292321);
  static const textSecondary = Color(0xFF665E5A);
  static const cardSurface = Color(0xFFFFFDFC);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: accent,
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: textPrimary),
        headlineMedium: TextStyle(
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: textPrimary),
        titleLarge: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: textPrimary),
        titleMedium: TextStyle(
            fontSize: 17,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 1,
        shadowColor: Color(0x1A6D5E59),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFFEFE3DB)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardSurface,
        selectedColor: primary,
        disabledColor: Color(0xFFF1E9E3),
        side: BorderSide(color: Color(0xFFDCCBC1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 13, color: textPrimary),
        secondaryLabelStyle: const TextStyle(fontSize: 13, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4DCD6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4DCD6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: Color(0xFFFF6B61),
      secondary: Color(0xFFFFB174),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Color(0xFF1D1715),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1D1715),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Color(0xFF2B211E),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Color(0xFF493934)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF2B211E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF493934)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF493934)),
        ),
      ),
    );
  }
}
