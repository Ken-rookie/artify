import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF292824);
  static const orange = Color(0xFFF2A33A);
  static const muted = Color(0xFF85827C);
  static const line = Color(0xFFE5E1DA);
}

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      brightness: Brightness.light,
      surface: const Color(0xFFFAF9F6),
    ),
    scaffoldBackgroundColor: const Color(0xFFFAF9F6),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFAF9F6),
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    ),
  );
}