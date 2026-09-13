import 'package:flutter/material.dart';

/// RishtaBook design tokens — "Sacred Union": deep maroon and warm gold
/// on a cream body, evoking a premium matrimonial identity. Token names are
/// unchanged so every existing `AppColors.x` reference repaints automatically.
class AppColors {
  AppColors._();

  // Primary — Maroon
  static const saffron = Color(0xFF800020);
  static const safLight = Color(0xFFFCE4EC);
  static const safDark = Color(0xFF5C0018);

  // Secondary — Rose gold (hearts, interests, debit transactions)
  static const rose = Color(0xFFB76E79);
  static const roseLight = Color(0xFFF8E8EA);

  // Kundali / Premium — Amber gold
  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFFBF0DC);

  // Verified / Accepted / credit transactions — Teal
  static const teal = Color(0xFF0F7C6E);
  static const tealLight = Color(0xFFE0F5F2);

  // Neutrals
  static const ink = Color(0xFF2B1A1A);
  static const muted = Color(0xFF6B5A5A);
  static const ghost = Color(0xFF8A7575);
  static const pageBg = Color(0xFFFFF8E1);
  static const cardBg = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFE8D5C4);
  static const headerBg = Color(0xFF800020);
  static const headerBgStart = Color(0xFF5C0018);
  static const brandGold = Color(0xFFD4AF37);

  static const error = Color(0xFFB3261E);
  static const success = Color(0xFF1E7A4C);

  /// Brand header gradient — deep maroon → maroon → rose gold.
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerBgStart, headerBg, rose],
  );

  /// Shorter two-stop gradient for small badges and icon tiles.
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerBg, gold],
  );
}
