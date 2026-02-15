import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette
  static const Color accentBlue = Color(0xFF5186d2);
  static const Color accentYellow = Color(0xFFEEE544);

  // Backgrounds & Surfaces
  static const Color mainDark = Color.fromARGB(255, 0, 0, 0);
  static const Color mainDarkLight = Color.fromARGB(255, 0, 0, 0);
  static const Color background = mainDark;

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mainDarkLight, mainDark],
  );

  static const Color surfaceWhite = Color(0xFFf5f5f5);
  static const Color surfaceDark = Color(0xFF0a0d11);
  static const Color surfacePlayer = Color(
    0xFF121212,
  ); // Deep Charcoal / Eerie Black
  static const Color surfacePopover = Color(0xFF121212);

  // Text Colors
  static const Color textMain = Colors.white;
  static const Color textLight = Colors.black;
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textDim = Color(0x66FFFFFF); // White with 40% opacity
}

class AppTextStyles {
  static TextStyle outfit({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textMain,
    double? letterSpacing,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Common Presets
  static TextStyle get titleLarge =>
      outfit(fontSize: 24, fontWeight: FontWeight.bold);
  static TextStyle get titleMedium =>
      outfit(fontSize: 18, fontWeight: FontWeight.bold);
  static TextStyle get bodyMain => outfit(fontSize: 16);
  static TextStyle get bodySmall =>
      outfit(fontSize: 14, color: AppColors.textGrey);
  static TextStyle get caption => outfit(
    fontSize: 12,
    color: AppColors.textGrey,
    fontWeight: FontWeight.w600,
  );
}

class AppRadius {
  static const double large = 40.0;
  static const double medium = 20.0;
  static const double small = 8.0;
}

class AppAssets {
  static const String logo = "assets/icons/logo_icon.svg";
  static const String home = "assets/icons/home_icon.svg";
  static const String search = "assets/icons/search_icon.svg";
  static const String collection = "assets/icons/collection_icon.svg";
  static const String play = "assets/icons/play_icon.svg";
  static const String pause = "assets/icons/pause_icon.svg";
}
