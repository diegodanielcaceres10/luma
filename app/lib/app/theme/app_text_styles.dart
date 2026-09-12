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
}
