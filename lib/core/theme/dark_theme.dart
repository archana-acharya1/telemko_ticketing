import 'package:flutter/material.dart';
import 'app_colors.dart';

class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,

      useMaterial3: false,

      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      iconTheme: const IconThemeData(color: AppColors.primaryRed),

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRed,
        secondary: AppColors.primaryRed,
        surface: AppColors.darkCard,
        background: AppColors.darkBackground,
        onSurface: Colors.white,
        onPrimary: Colors.black,
      ),

      scaffoldBackgroundColor: AppColors.darkBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),


      cardColor: AppColors.darkCard,

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.grey,
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: AppColors.primaryRed,
        suffixIconColor: AppColors.primaryRed,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
      ),
    );
  }
}
