import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static TextStyle get displayLarge =>
      GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5);
  static TextStyle get displayMedium =>
      GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3);
  static TextStyle get headingLarge =>
      GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3);
  static TextStyle get headingMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink);
  static TextStyle get headingSmall =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.2);
  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted);
  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted);
  static TextStyle get caption =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.ghost);
  static TextStyle get captionBold =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ghost, letterSpacing: 0.4);
  static TextStyle get label =>
      GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.ghost, letterSpacing: 0.5);

  // On dark header
  static TextStyle get headerTitle =>
      GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3);
  static TextStyle get headerBody =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xD9FFFFFF));
  static TextStyle get headerSubtitle =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xB3FFFFFF));

  // Brand wordmark on gradient headers
  static TextStyle get brandLogoRishta => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
      );
  static TextStyle get brandLogoBook => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.brandGold,
        letterSpacing: -0.5,
      );
  static TextStyle get brandLogoRishtaLarge => GoogleFonts.playfairDisplay(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.3,
      );
  static TextStyle get brandLogoBookLarge => GoogleFonts.playfairDisplay(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        color: AppColors.brandGold,
        letterSpacing: 0.3,
      );

  // Form section titles (Complete Profile, etc.)
  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.saffron,
        letterSpacing: -0.2,
      );
}
