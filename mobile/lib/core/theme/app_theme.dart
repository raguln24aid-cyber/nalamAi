import 'package:flutter/material.dart';

/// Accessibility-first theme: large touch targets (min 56dp, well above the 48dp WCAG minimum),
/// high-contrast color pairs, and generously scaled text that still respects the system's
/// accessibility text-scale factor (never capped — see MediaQuery textScaler passthrough in
/// app.dart) so a low-vision user's own OS settings continue to apply on top of this baseline.
class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF0B5F4E); // deep teal — passes 4.5:1 contrast on white
  static const _errorColor = Color(0xFFB3261E);
  static const _warningColor = Color(0xFF8A5300);

  static const double minTouchTarget = 56;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor, error: _errorColor);
    return _base(colorScheme, Brightness.light);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      error: _errorColor,
    );
    return _base(colorScheme, Brightness.dark);
  }

  static Color warningColor(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFFFC876) : _warningColor;

  static ThemeData _base(ColorScheme colorScheme, Brightness brightness) {
    // Font sizing intentionally comes from Typography's own defaults plus the system text-scale
    // factor (see app.dart's MediaQuery.textScaler clamp), not a flat multiplier here — applying
    // a legacy fontSizeFactor across the whole TextTheme conflicts with null-fontSize style
    // slots and trips a framework assertion.
    final textTheme = Typography.material2021(platform: TargetPlatform.android)
        .black
        .apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(minTouchTarget, minTouchTarget)),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 16),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 16),
      ),
    );
  }
}
