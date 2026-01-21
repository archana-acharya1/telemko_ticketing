// SPACING & PADDING
import 'package:flutter/cupertino.dart';

class AppPadding {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Predefined EdgeInsets
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);

  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);

  static const EdgeInsets screen = EdgeInsets.all(md);
}

// BORDER RADIUS
class AppRadius {
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double circle = 50.0;

  // Predefined BorderRadius
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
}

// SIZES & DIMENSIONS
class AppSizes {
  // Icons
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Buttons (Accessibility)
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0; // Minimum accessible size
  static const double buttonHeightLg = 56.0;
  static const double buttonMinWidth = 48.0;

  // App Components
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 56.0;
  static const double textFieldHeight = 48.0;

  // Cards
  static const double cardElevationSm = 1.0;
  static const double cardElevationMd = 2.0;
  static const double cardElevationLg = 4.0;

  // Specific Components
  static const double qrCardElevation = 4.0;
  static const double qrCardBorderRadius = 20.0;
  static const double qrCardPadding = 24.0;
  static const double qrImageHeight = 250.0;

  static const double bankCardElevation = 2.0;
  static const double bankCardBorderRadius = 12.0;

  // Dividers
  static const double dividerThickness = 1.0;

  // Loading Indicators
  static const double loadingIndicatorSm = 20.0;
  static const double loadingIndicatorMd = 32.0;
  static const double loadingIndicatorLg = 48.0;
}