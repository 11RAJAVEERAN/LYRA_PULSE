import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static final TextStyle display = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle headline = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle title = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static final TextStyle label = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static final TextTheme textTheme = ThemeData()
      .textTheme
      .apply(fontFamily: GoogleFonts.inter().fontFamily)
      .copyWith(
        displayLarge: display,
        displayMedium: display.copyWith(fontSize: 30),
        displaySmall: display.copyWith(fontSize: 28),
        headlineLarge: headline,
        headlineMedium: headline,
        headlineSmall: headline.copyWith(fontSize: 22),
        titleLarge: title,
        titleMedium: title.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: label,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: bodySmall,
        labelLarge: label,
        labelMedium: label.copyWith(fontSize: 12),
        labelSmall: label.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
      );
}
