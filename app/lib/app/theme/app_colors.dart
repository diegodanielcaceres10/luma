import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);

  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  static const border = Color(0xFFE2E8F0);

  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);

  // Auth screens (dark, brand background).
  static const authBackgroundTop = Color(0xFF12291D);
  static const authBackgroundBottom = Color(0xFF020604);
  static const authGlow = Color(0xFF1F7A4C);

  static const authAccent = Color(0xFF4CBB7A);
  static const authAccentDark = Color(0xFF1F7A4C);

  static const authTextPrimary = Color(0xFFFFFFFF);
  static const authTextSecondary = Color(0xFFAFC2B8);
  static const authTextFooter = Color(0xFF6C7F76);
}
