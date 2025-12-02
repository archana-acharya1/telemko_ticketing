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

      iconTheme: const IconThemeData(color: AppColors.primaryBlue),

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
        surface: AppColors.lightCard,
        background: AppColors.lightBackground,
        onSurface: Colors.black,
        onPrimary: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),


      cardColor: AppColors.lightCard,

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.black54,
      ),

      inputDecorationTheme: InputDecorationTheme(
        prefixIconColor: AppColors.primaryBlue,
        suffixIconColor: AppColors.primaryBlue,
        labelStyle: const TextStyle(color: Colors.black87),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.lightBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }
}
