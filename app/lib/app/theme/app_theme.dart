import 'package:flutter/material.dart';

import '../../core/widgets/layout/max_width_frame.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      // Material 3's default Android zoom transition briefly flashes the
      // background; use the classic slide-up instead.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      // Sheets open on the root navigator, outside the shell's width cap.
      bottomSheetTheme: const BottomSheetThemeData(
        constraints: BoxConstraints(maxWidth: kAppMaxContentWidth),
      ),
      // Dialogs also open on the root navigator. minWidth keeps Material's
      // default, which this constraint replaces.
      dialogTheme: const DialogThemeData(
        constraints: BoxConstraints(minWidth: 280, maxWidth: kDialogMaxWidth),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
