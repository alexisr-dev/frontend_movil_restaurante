import 'package:flutter/material.dart';

/// Paleta tomada del panel web: chicha morada, aji amarillo, limon y rocoto.
class Paleta {
  static const tinta = Color(0xFF1A1B2E);
  static const papel = Color(0xFFF5F3F7);
  static const lienzo = Colors.white;
  static const chicha = Color(0xFF5B2A86);
  static const chichaClaro = Color(0xFF7C4BAB);
  static const aji = Color(0xFFE8A00D);
  static const limon = Color(0xFF6FA80A);
  static const rocoto = Color(0xFFC42348);
  static const tenue = Color(0xFF6B6C81);
}

class AppTheme {
  static ThemeData get claro {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Paleta.chicha,
        primary: Paleta.chicha,
        secondary: Paleta.aji,
        error: Paleta.rocoto,
        surface: Paleta.lienzo,
      ),
      scaffoldBackgroundColor: Paleta.papel,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Paleta.tinta,
        displayColor: Paleta.tinta,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Paleta.papel,
        foregroundColor: Paleta.tinta,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Paleta.tinta,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: Paleta.lienzo,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x141A1B2E)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Paleta.lienzo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x241A1B2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x241A1B2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Paleta.chicha, width: 2),
        ),
        labelStyle: const TextStyle(color: Paleta.tenue),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Paleta.chicha,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Paleta.tinta,
          side: const BorderSide(color: Color(0x241A1B2E)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Paleta.tinta,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x141A1B2E), space: 1),
    );
  }
}
