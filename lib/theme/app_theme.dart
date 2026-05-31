import 'package:flutter/material.dart';

class AppColors {
  static const Color toscaDark = Color(0xFF0F3D1A);
  static const Color tosca = Color(0xFF14532D);
  static const Color toscaLight = Color(0xFF1D7A3E);
  static const Color mintBackground = Color(0xFFE8F5E9);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Colors.white;
  
  // Figma Theme Colors
  static const Color goldAccent = Color(0xFFEAB308); // Yellow/gold accent for buttons
  static const Color creamBand = Color(0xFFECE6D2); // Elegant cream stripe for splash screen
  
  // Status Colors
  static const Color greenHadir = Color(0xFF10B981);
  static const Color orangeIzin = Color(0xFFF59E0B);
  static const Color blueSakit = Color(0xFF3B82F6);
  static const Color redAlpa = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.tosca,
        primary: AppColors.tosca,
        secondary: AppColors.toscaLight,
        background: AppColors.background,
      ),
      fontFamily: 'Inter', // Default system font fallback
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          color: AppColors.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
