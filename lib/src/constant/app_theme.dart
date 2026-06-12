// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ── Warna utama ──
  static const primary = Color(0xFF6886F3);
  static const gradient = Color(0xFFFA3D66);
  static const primarySoft = Color(0xFFDFF5EF);
  static const secondary = Color(0xFFF4A261);
  static const background = Color(0xFFF7F8F4);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF102A43);
  static const textSecondary = Color(0xFF627D98);
  static const border = Color(0xFFD9E2EC);
  static const success = Color(0xFF1F9D55);
  static const warning = Color(0xFFDB7C00);
  static const danger = Color(0xFFCF3C3C);

  // ── Warna akurasi (Sementara menggunakan primary) ──
  static Color confidenceColor(double confidence) {
    if (confidence >= 0.75) return primary;
    if (confidence >= 0.50) return Colors.orange;
    return primary;
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      secondary: primary,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: primary.withValues(alpha: 0.2),
      side: const BorderSide(color: primary),
      labelStyle: const TextStyle(color: primary),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: textSecondary,
      ),
    ),
  );
}
