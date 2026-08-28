import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color azulProfundo = Color(0xFF0A2540);
  static const Color amarilloSol = Color(0xFFFFC107);
  static const Color amarilloSolDark = Color(0xFFFDC003);

  // Surfaces and Backgrounds
  static const Color backgroundLight = Color(0xFFF9F9F9);
  static const Color surfaceMuted = Color(0xFFF1F4F9);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Dark Mode Surfaces
  static const Color backgroundDark = Color(0xFF1A1C1C);
  static const Color surfaceDark = Color(0xFF25282A);
  static const Color cardDark = Color(0xFF2F3131);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0A2540);
  static const Color textSecondaryLight = Color(0xFF43474D);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFC4C6CE);

  // Expiration Status Colors
  // > 7 days: Green
  static const Color statusGreenText = Color(0xFF1B5E20);
  static const Color statusGreenBg = Color(0xFFE8F5E9);

  // 3 to 7 days: Yellow/Warning
  static const Color statusYellowText = Color(0xFF826100);
  static const Color statusYellowBg = Color(0xFFFFF8E1);

  // < 3 days: Red/Danger
  static const Color statusRedText = Color(0xFF93000A);
  static const Color statusRedBg = Color(0xFFFFDAD6);
}
