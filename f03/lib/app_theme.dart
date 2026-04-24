import 'package:flutter/material.dart';

/// Palette admin KeBook (đồng bộ tông tím với yêu cầu UI).
abstract final class AppColors {
  static const Color primary = Color(0xFF6D28D9);
  static const Color primaryContainer = Color(0xFFF5F3FF);
  static const Color onPrimaryContainer = Color(0xFF2E1065);
  static const Color background = Color(0xFFF6F5FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0EDFB);
  static const Color outline = Color(0xFFE6E1F5);
  static const Color onSurface = Color(0xFF1D1B2E);
  static const Color onSurfaceVariant = Color(0xFF6B6885);
}

/// ColorScheme + ThemeData dùng cho MaterialApp (mobile-first).
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
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.primary,
      textColor: AppColors.onSurface,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minVerticalPadding: 10,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: const BorderSide(color: AppColors.outline),
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryContainer,
      secondarySelectedColor: AppColors.primaryContainer,
      labelStyle: const TextStyle(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.onPrimaryContainer,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      showCheckmark: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          size: 24,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
    ),
  );
}
