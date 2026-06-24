import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema moderno dell'app (Material 3).
class AppTheme {
  static const seed = Color(0xFF0B3D66); // blu SNA

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF6F7F9),
      // Ripple più visibile al tocco.
      splashColor: seed.withValues(alpha: 0.20),
      highlightColor: seed.withValues(alpha: 0.10),
      // Titoli navy: AppBar di tutte le schermate + stili "title" del tema.
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(color: kNavy),
        titleMedium: base.textTheme.titleMedium?.copyWith(color: kNavy),
        titleSmall: base.textTheme.titleSmall?.copyWith(color: kNavy),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(color: kNavy),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(color: kNavy),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        titleTextStyle: TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        color: Colors.white,
        surfaceTintColor: Colors.white, // niente tinta M3: card bianche con ombra reale
        shadowColor: Colors.black.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
