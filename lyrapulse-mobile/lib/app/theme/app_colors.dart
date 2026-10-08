import 'package:flutter/material.dart';

// LYRA PULSE semantic color tokens.
// Matches the LYRA PULSE Admin theme.

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF172554);
  static const Color primaryDark = Color(0xFF0B1638);
  static const Color primaryBlue = Color(0xFF2563EB);

  // Secondary / Accent
  static const Color secondary = Color(0xFF4F46E5);
  static const Color secondaryDark = Color(0xFF4338CA);
  static const Color secondarySoft = Color(0xFFEEF2FF);
  static const Color accent = Color(0xFF06B6D4);

  // Background / Surface
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Borders / UI
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFF94A3B8);
  static const Color hover = Color(0xFFF1F5F9);
  static const Color focus = Color(0xFF2563EB);
  static const Color disabled = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF15803D);
  static const Color successBackground = Color(0xFFF0FDF4);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFF92400E);
  static const Color warningBackground = Color(0xFFFFFBEB);

  static const Color error = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFB91C1C);
  static const Color errorBackground = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF2563EB);
  static const Color infoDark = Color(0xFF1D4ED8);
  static const Color infoBackground = Color(0xFFEFF6FF);

  // Sidebar
  static const Color sidebarText = Color(0xFFCBD5E1);
  static const Color sidebarMuted = Color(0xFF94A3B8);

  // Transparent UI states
  static const Color sidebarActive = Color.fromRGBO(37, 99, 235, 0.24);
  static const Color sidebarHover = Color.fromRGBO(203, 213, 225, 0.09);
  static const Color sidebarDivider = Color.fromRGBO(203, 213, 225, 0.12);

  static const Color focusRing = Color.fromRGBO(37, 99, 235, 0.12);
  static const Color focusSubtle = Color.fromRGBO(37, 99, 235, 0.10);
  static const Color selection = Color.fromRGBO(37, 99, 235, 0.18);
  static const Color selected = Color.fromRGBO(37, 99, 235, 0.08);
}