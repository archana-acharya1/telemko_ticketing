import 'package:flutter/material.dart';
import 'app_colors.dart';

class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,

      useMaterial3: false,

      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      iconTheme: const IconThemeData(color: AppColors.primaryRed),

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryRed,
        secondary: AppColors.primaryRed,
        surface: AppColors.lightCard,
        background: AppColors.lightBackground,
        onSurface: Colors.black,
        onPrimary: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),


      cardColor: AppColors.lightCard,

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: Colors.black54,
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: AppColors.primaryRed,
        suffixIconColor: AppColors.primaryRed,
        labelStyle: const TextStyle(color: Colors.black87),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.lightRed),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
        ),
      ),
    );
  }
}
