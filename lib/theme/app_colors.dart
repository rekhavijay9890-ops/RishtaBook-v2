import 'package:flutter/material.dart';

/// RishtaBook v3 design tokens — saffron/rose/gold/teal on a dark header,
/// warm-white body. Replaces the old maroon/marigold palette.
class AppColors {
  AppColors._();

  // Primary — Saffron
  static const saffron  = Color(0xFFE8650A);
  static const safLight = Color(0xFFFFF0E6);
  static const safDark  = Color(0xFFB84D00);

  // Secondary — Rose (hearts, interests, debit transactions)
  static const rose      = Color(0xFFC0394B);
  static const roseLight = Color(0xFFFDEDF0);

  // Kundali / Premium — Gold
  static const gold      = Color(0xFFC8920A);
  static const goldLight = Color(0xFFFFF8E1);

  // Verified / Accepted / credit transactions — Teal
  static const teal      = Color(0xFF0F7C6E);
  static const tealLight = Color(0xFFE0F5F2);

  // Neutrals
  static const ink         = Color(0xFF1A1018);
  static const muted       = Color(0xFF6B5F69);
  static const ghost       = Color(0xFFA89FA7);
  static const pageBg      = Color(0xFFFAF6F8);
  static const cardBg      = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFEDE4EB);
  static const headerBg    = Color(0xFF1A1018);

  static const error   = Color(0xFFB3261E);
  static const success = Color(0xFF1E7A4C);
}
