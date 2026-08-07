import 'package:flutter/material.dart';

/// RishtaBook v5 design tokens — "Orchid Bloom": a neutral violet/plum
/// identity (no single-religion association) on a cool lavender-white
/// body, with a colored (not near-black) header. Same token names as v3/v4
/// so every existing `AppColors.x` reference across the app repaints
/// automatically - only the values changed. Neutrals were also darkened
/// vs v4 (ghost/muted) to fix low-contrast caption/label text.
class AppColors {
  AppColors._();

  // Primary — Orchid
  static const saffron  = Color(0xFF7C4DBF);
  static const safLight = Color(0xFFF1E9FB);
  static const safDark  = Color(0xFF5A3690);

  // Secondary — Magenta rose (hearts, interests, debit transactions)
  static const rose      = Color(0xFFC1447F);
  static const roseLight = Color(0xFFFBE3EF);

  // Kundali / Premium — Amber gold (kept as a warm contrast accent)
  static const gold      = Color(0xFFB07A1E);
  static const goldLight = Color(0xFFFBF0DC);

  // Verified / Accepted / credit transactions — Teal (kept as a distinct
  // semantic accent, functionally separate from the brand hue)
  static const teal      = Color(0xFF0F7C6E);
  static const tealLight = Color(0xFFE0F5F2);

  // Neutrals
  static const ink         = Color(0xFF2B2438);
  static const muted       = Color(0xFF6B5E7B);
  static const ghost       = Color(0xFF8A7B99);
  static const pageBg      = Color(0xFFFAF7FD);
  static const cardBg      = Color(0xFFFFFFFF);
  static const borderColor = Color(0xFFEBE1F7);
  static const headerBg    = Color(0xFF7C4DBF);
  static const headerBgStart = Color(0xFF6B5E88);

  static const error   = Color(0xFFB3261E);
  static const success = Color(0xFF1E7A4C);

  /// Diagonal header treatment (muted plum into orchid) used on every
  /// screen's top bar in place of a flat headerBg fill.
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [headerBgStart, headerBg],
  );
}
