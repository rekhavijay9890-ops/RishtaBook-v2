import 'package:flutter/material.dart';

/// RishtaBook v4 design tokens — "Sindoor Sunset": sindoor red-orange into
/// marigold gold on a warm ivory body, with a colored (not near-black)
/// header. Same token names as v3 so every existing `AppColors.x` reference
/// across the app repaints automatically - only the values changed.
class AppColors {
  AppColors._();

  // Primary — Sindoor
  static const saffron  = Color(0xFFE2542D);
  static const safLight = Color(0xFFFDEBD6);
  static const safDark  = Color(0xFFB23D1D);

  // Secondary — Rose (hearts, interests, debit transactions)
  static const rose      = Color(0xFFD6486B);
  static const roseLight = Color(0xFFFBE4EA);

  // Kundali / Premium — Marigold gold
  static const gold      = Color(0xFFC77F1B);
  static const goldLight = Color(0xFFFDF1DC);

  // Verified / Accepted / credit transactions — Teal (kept as a distinct
  // semantic accent, functionally separate from the brand hue)
  static const teal      = Color(0xFF0F7C6E);
  static const tealLight = Color(0xFFE0F5F2);

  // Neutrals
  static const ink         = Color(0xFF3A2117);
  static const muted       = Color(0xFF9A6B52);
  static const ghost       = Color(0xFFBFA089);
  static const pageBg      = Color(0xFFFFF7EF);
  static const cardBg      = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFF6E1CB);
  static const headerBg    = Color(0xFFE2542D);

  static const error   = Color(0xFFB3261E);
  static const success = Color(0xFF1E7A4C);
}
