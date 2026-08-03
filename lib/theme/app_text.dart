import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  AppText._();

  static const displayLarge  = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5);
  static const displayMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3);
  static const headingLarge  = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.3);
  static const headingMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const headingSmall  = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.2);
  static const bodyMedium    = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted);
  static const bodySmall     = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted);
  static const caption       = TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.ghost);
  static const captionBold   = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ghost, letterSpacing: 0.4);
  static const label         = TextStyle(fontSize: 9,  fontWeight: FontWeight.w700, color: AppColors.ghost, letterSpacing: 0.5);

  // On dark header
  static const headerTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3);
  static const headerBody  = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFA89FA7));
}
