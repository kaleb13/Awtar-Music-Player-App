import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color accentYellow = Color(0xFFEEE544);

  // Backgrounds & Surfaces
  static const Color background = Colors.black;
  static const Color surfaceWhite = Colors.white;
  static const Color surfaceDark = Color(0xFF121212);

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
