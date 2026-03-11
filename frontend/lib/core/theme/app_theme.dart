import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0A6E6E);
  static const Color primaryLight = Color(0xFF13A89E);
  static const Color primaryDark = Color(0xFF054D4D);
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentSoft = Color(0xFFE6F9F5);
  static const Color surface = Color(0xFFF7FAFA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0D1F1F);
  static const Color textMid = Color(0xFF3D5A5A);
  static const Color textLight = Color(0xFF8AABAB);
  static const Color divider = Color(0xFFE0EEEE);
  static const Color error = Color(0xFFE05C5C);
  static const Color warning = Color(0xFFFFA743);
  static const Color success = Color(0xFF2ECC8A);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0A6E6E), Color(0xFF13A89E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Colors.white,
          error: error,
          onError: Colors.white,
          surface: surface,
          onSurface: textDark,
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: textDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(color: textLight, fontSize: 15),
        ),
      );
}
