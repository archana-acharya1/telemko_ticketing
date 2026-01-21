import 'package:flutter/material.dart';

class AppColors {
  // ========== BRAND COLORS (Used in both modes) ==========
  static const Color primaryBlue = Color(0xFF42A5F5); // Main brand color
  static const Color lightBlue = Color(0xFFBBDEFB);   // Soft background blue

  // ========== SEMANTIC COLORS (For both modes) ==========
  static const Color success = Color(0xFF4CAF50);     // Green
  static const Color warning = Color(0xFFFF9800);     // Orange
  static const Color error = Color(0xFFF44336);       // Red
  static const Color info = Color(0xFF2196F3);        // Info blue

  // ========== DARK MODE COLORS ==========
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkCardVariant = Color(0xFF252525);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextDisabled = Color(0xFF666666);
  static const Color darkBorder = Color(0xFF424242);
  static const Color darkDivider = Color(0xFF333333);

  // ========== LIGHT MODE COLORS ==========
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);
  static const Color lightCard = Color(0xFFE3F2FD);
  static const Color lightCardVariant = Color(0xFFF5FAFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextDisabled = Color(0xFF9E9E9E);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // ========== GRADIENTS (Adaptive) ==========
  static List<Color> getBackgroundGradient(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (brightness == Brightness.dark) {
      return [
        Color(0xFF1A1A1A),
        Color(0xFF121212),
        Color(0xFF0A0A0A),
      ];
    } else {
      return [
        Color(0xFFF5FAFF),
        Color(0xFFEAF3FD),
        Color(0xFFE0ECFB),
      ];
    }
  }

  // ========== THEME-AWARE GETTERS ==========
  static Color getBackground(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getCardColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkCard : lightCard;
  }

  static Color getTextColor(BuildContext context, {bool primary = true}) {
    final brightness = Theme.of(context).brightness;

    if (primary) {
      return brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
    } else {
      return brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
    }
  }

  static Color getBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkBorder : lightBorder;
  }

  static Color getDividerColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkDivider : lightDivider;
  }

  // ========== ADAPTIVE COLOR SCHEME (Recommended for Material 3) ==========
  static ColorScheme getColorScheme(Brightness brightness) {
    return ColorScheme(
      brightness: brightness,

      // Primary colors
      primary: primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: brightness == Brightness.dark
          ? Color(0xFF0D47A1)
          : Color(0xFFBBDEFB),

      // Secondary colors
      secondary: brightness == Brightness.dark
          ? Color(0xFF64B5F6)
          : Color(0xFF1976D2),
      onSecondary: Colors.white,
      secondaryContainer: brightness == Brightness.dark
          ? Color(0xFF0D365A)
          : Color(0xFFE3F2FD),

      // Surface colors
      surface: brightness == Brightness.dark ? darkSurface : lightSurface,
      onSurface: brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary,
      surfaceVariant: brightness == Brightness.dark
          ? darkSurfaceVariant
          : lightSurfaceVariant,
      onSurfaceVariant: brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary,

      // Background colors
      background: brightness == Brightness.dark ? darkBackground : lightBackground,
      onBackground: brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary,

      // Error colors
      error: error,
      onError: Colors.white,
      errorContainer: brightness == Brightness.dark
          ? Color(0x55F44336)
          : Color(0x22F44336),

      // Outline colors
      outline: brightness == Brightness.dark ? darkBorder : lightBorder,
      outlineVariant: brightness == Brightness.dark
          ? Color(0xFF555555)
          : Color(0xFFCCCCCC),

      // Other colors
      shadow: brightness == Brightness.dark
          ? Colors.black.withOpacity(0.5)
          : Colors.black.withOpacity(0.1),
      scrim: brightness == Brightness.dark
          ? Colors.black.withOpacity(0.6)
          : Colors.black.withOpacity(0.4),
      inverseSurface: brightness == Brightness.dark
          ? lightSurface
          : darkSurface,
      onInverseSurface: brightness == Brightness.dark
          ? lightTextPrimary
          : darkTextPrimary,
      surfaceTint: primaryBlue,
    );
  }

  // ========== ACCESSIBILITY UTILITIES ==========
  static bool hasSufficientContrast(Color color1, Color color2) {
    final luminance1 = _getRelativeLuminance(color1);
    final luminance2 = _getRelativeLuminance(color2);
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 < luminance2 ? luminance1 : luminance2;
    return (lighter + 0.05) / (darker + 0.05) >= 4.5;
  }

  static double _getRelativeLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final rs = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) * ((r + 0.055) / 1.055);
    final gs = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) * ((g + 0.055) / 1.055);
    final bs = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) * ((b + 0.055) / 1.055);

    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
  }

  // ========== QUICK COLOR CHECKS ==========
  static void printContrastRatios(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = getColorScheme(brightness);

    print('=== CONTRAST RATIO CHECK (${brightness.toString().split('.').last}) ===');
    print('Primary/OnPrimary: ${hasSufficientContrast(scheme.primary, scheme.onPrimary)}');
    print('Surface/OnSurface: ${hasSufficientContrast(scheme.surface, scheme.onSurface)}');
    print('Background/OnBackground: ${hasSufficientContrast(scheme.background, scheme.onBackground)}');
    print('Error/OnError: ${hasSufficientContrast(scheme.error, scheme.onError)}');
  }
}