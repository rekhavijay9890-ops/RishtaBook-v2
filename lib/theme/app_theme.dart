import 'package:flutter/material.dart';

/// RishtaBook design tokens.
///
/// Palette is drawn from Indian wedding-card materials rather than a
/// generic "app teal": deep rani/maroon for warmth and trust, marigold
/// gold for celebration accents, warm ivory instead of stark white.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFBF6EF); // warm ivory
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3E9DD); // soft sandalwood

  static const Color primary = Color(0xFF8C1D40); // rani / deep maroon
  static const Color primaryDark = Color(0xFF651530);
  static const Color primaryLight = Color(0xFFB24866);

  static const Color accent = Color(0xFFCC9A3D); // marigold gold
  static const Color accentLight = Color(0xFFE8C57A);

  static const Color trust = Color(0xFF0F6E5D); // used for "verified"/success

  static const Color ink = Color(0xFF2A1E1A); // warm near-black
  static const Color muted = Color(0xFF8A7B72); // warm grey-brown
  static const Color divider = Color(0xFFE7DCCC);

  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF1E7A4C);

  static const List<Color> heroGradient = [
    Color(0xFF8C1D40),
    Color(0xFF651530),
  ];
}

class AppRadii {
  AppRadii._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base) {
    final display = base;
    final body = base;
    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: AppColors.ink),
      displayMedium: display.displayMedium?.copyWith(color: AppColors.ink),
      displaySmall: display.displaySmall?.copyWith(color: AppColors.ink),
      headlineLarge: display.headlineLarge
          ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      headlineMedium: display.headlineMedium
          ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      headlineSmall: display.headlineSmall
          ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      titleLarge:
          body.titleLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
      titleMedium:
          body.titleMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      titleSmall:
          body.titleSmall?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ink),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.muted),
      labelLarge:
          body.labelLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _textTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.surface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'serif',
        ),
        iconTheme: const IconThemeData(color: AppColors.surface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.primary.withOpacity(0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.divider, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: AppColors.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
