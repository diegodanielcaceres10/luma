import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.text,
  );

  // Auth screens (dark background).
  static const authTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: AppColors.authTextPrimary,
    letterSpacing: -0.5,
  );

  static const authSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextSecondary,
    height: 1.5,
  );

  static const authFooter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.authTextFooter,
    height: 1.6,
  );
}
