import 'package:flutter/material.dart';

// ============================================================
// SEGREDUINO — Global Color Palette & Theme
// ============================================================
// Usage:
//   import 'app_theme.dart'; // adjust path as needed
//   MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, ...)
//
// Direct color access:
//   AppColors.primary        → main green
//   AppColors.biodegradable  → green for bio bin
//   AppColors.recyclable     → blue for recyclable bin
//   AppColors.nonBio         → orange for non-bio bin
//   AppColors.danger         → red for alerts/overflow
//   AppColors.surface        → card/surface background
// ============================================================

abstract class AppColors {
  // ── Brand / Primary ────────────────────────────────────────
  static const Color primary        = Color(0xFF2E7D32); // Deep forest green
  static const Color primaryLight   = Color(0xFF60AD5E); // Mid green (buttons, chips)
  static const Color primarySurface = Color(0xFFE8F5E9); // Very light green (bg tints)

  // ── Bin-type Semantic Colors ───────────────────────────────
  static const Color biodegradable     = Color(0xFF388E3C); // Green
  static const Color biodegradableBg   = Color(0xFFE8F5E9);
  static const Color recyclable        = Color(0xFF1565C0); // Blue
  static const Color recyclableBg      = Color(0xFFE3F2FD);
  static const Color nonBio            = Color(0xFFE65100); // Deep orange
  static const Color nonBioBg          = Color(0xFFFFF3E0);

  // ── Status Colors ──────────────────────────────────────────
  static const Color danger            = Color(0xFFC62828); // Red — overflow/errors
  static const Color dangerBg          = Color(0xFFFFEBEE);
  static const Color warning           = Color(0xFFF57F17); // Amber — warnings
  static const Color warningBg         = Color(0xFFFFFDE7);
  static const Color success           = Color(0xFF2E7D32); // Same as primary
  static const Color successBg         = Color(0xFFE8F5E9);

  // ── Neutral / Surface ──────────────────────────────────────
  static const Color surface           = Color(0xFFFFFFFF);
  static const Color surfaceVariant    = Color(0xFFF5F7F5); // Off-white page bg
  static const Color outline           = Color(0xFFDAE3DA); // Dividers, borders
  static const Color onSurface        = Color(0xFF1B2B1B); // Primary text (near-black)
  static const Color onSurfaceVariant = Color(0xFF5C6B5C); // Secondary text
  static const Color disabled         = Color(0xFFB0BEB0); // Disabled text/icons

  // ── Scheduled / Locked ─────────────────────────────────────
  static const Color locked           = Color(0xFF78909C); // Blue-grey
  static const Color lockedBg         = Color(0xFFECEFF1);
}

// ── Bin-type helper ───────────────────────────────────────────
abstract class BinColors {
  static Color foreground(String binType) {
    final t = binType.toLowerCase();
    if (t.contains('bio') && !t.contains('non')) return AppColors.biodegradable;
    if (t.contains('recycl'))                    return AppColors.recyclable;
    if (t.contains('non'))                       return AppColors.nonBio;
    return AppColors.primary;
  }

  static Color background(String binType) {
    final t = binType.toLowerCase();
    if (t.contains('bio') && !t.contains('non')) return AppColors.biodegradableBg;
    if (t.contains('recycl'))                    return AppColors.recyclableBg;
    if (t.contains('non'))                       return AppColors.nonBioBg;
    return AppColors.primarySurface;
  }

  static IconData icon(String binType) {
    final t = binType.toLowerCase();
    if (t.contains('bio') && !t.contains('non')) return Icons.eco_rounded;
    if (t.contains('recycl'))                    return Icons.recycling_rounded;
    if (t.contains('non'))                       return Icons.delete_outline_rounded;
    return Icons.delete_rounded;
  }
}

// ── Material 3 Light Theme ────────────────────────────────────
abstract class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySurface,
      onPrimaryContainer: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.surfaceVariant,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.outline,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.outline),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 24,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: AppColors.outline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Colors.black,
      primaryContainer: const Color(0xFF1B3A1B),
      surface: const Color(0xFF121712),
      onSurface: const Color(0xFFE2EBE2),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: const Color(0xFF0E130E),
      appBarTheme: AppBarTheme(
        backgroundColor: base.surface,
        foregroundColor: base.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}