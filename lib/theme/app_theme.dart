import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF090D16);
  static const bgCard = Color(0xFF0F1629);
  static const bgSurface = Color(0xFF1E293B);
  static const violet = Color(0xFF635BFF);
  static const violetLight = Color(0xFF818CF8);
  static const mint = Color(0xFF00FFC2);
  static const textMain = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFF1E293B);
  static const recording = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        secondary: AppColors.mint,
        surface: AppColors.bgCard,
        error: AppColors.recording,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.violet,
        unselectedItemColor: AppColors.textMuted,
      ),
    );
  }
}
