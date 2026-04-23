import 'package:flutter/material.dart';

/// Palette admin KeBook (đồng bộ tông tím với yêu cầu UI).
abstract final class AppColors {
  static const Color primary = Color(0xFF6D28D9);
  static const Color primaryContainer = Color(0xFFF5F3FF);
  static const Color onPrimaryContainer = Color(0xFF2E1065);
  static const Color background = Color(0xFFF6F5FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFE6E1F5);
  static const Color onSurface = Color(0xFF1D1B2E);
  static const Color onSurfaceVariant = Color(0xFF6B6885);
}

/// ColorScheme + ThemeData dùng cho MaterialApp.
ThemeData buildKeBookAdminTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
    ),
  );
}
