import 'package:flutter/material.dart';

class AppTheme {
  // Deep Cinema Color Palette
  static const Color background = Color(0xFF0C0E14);
  static const Color surface = Color(0xFF131722);
  static const Color surfaceElevated = Color(0xFF1A1F2C);
  static const Color cardColor = Color(0xFF161A25);

  // Single Accent: Cinematheque Vermilion
  static const Color accentVermilion = Color(0xFFE23D28);
  static const Color accentCrimson = Color(0xFFE23D28);
  static const Color primaryAmber = Color(0xFFE23D28);
  static const Color accentCyan = Color(0xFFF4F2EC);

  // Neutrals & Paper Tones
  static const Color textPrimary = Color(0xFFF4F2EC);
  static const Color textSecondary = Color(0xFF9EA3B0);
  static const Color textMuted = Color(0xFF5E6373);
  static const Color ratingStar = Color(0xFFE8A838);

  // Borders & Dividers
  static const Color borderLight = Color(0xFF232838);
  static const Color borderSubtle = Color(0xFF191D2A);

  // Font Families
  static const String fontDisplay = 'Newsreader';
  static const String fontText = 'Plus Jakarta Sans';
  static const String fontMono = 'Space Mono';

  // Reusable Text Styles
  static const TextStyle displayTitle = TextStyle(
    fontFamily: fontDisplay,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: textPrimary,
    height: 1.15,
  );

  static const TextStyle monoTag = TextStyle(
    fontFamily: fontMono,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: textSecondary,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontText,
    fontSize: 13,
    color: textPrimary,
    height: 1.5,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentVermilion,
      cardColor: cardColor,
      fontFamily: fontText,
      colorScheme: const ColorScheme.dark(
        primary: accentVermilion,
        secondary: textPrimary,
        surface: surface,
        error: accentVermilion,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontDisplay,
          color: textPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accentVermilion,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: accentVermilion, width: 1.2),
        ),
        hintStyle: const TextStyle(
          color: textMuted,
          fontSize: 13,
          fontFamily: fontText,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentVermilion,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          textStyle: const TextStyle(
            fontFamily: fontMono,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderLight, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          textStyle: const TextStyle(
            fontFamily: fontMono,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
