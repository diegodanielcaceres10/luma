import 'package:flutter/material.dart';

import '../../core/widgets/primary_button.dart';
import '../theme/app_colors.dart';

/// Shown when the app could not start (for example the backend failed to
/// initialize), so the splash doesn't loop forever with no way out.
class BootstrapErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const BootstrapErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackgroundTop,
      body: SafeArea(
        child: Center(
          // Scrolls instead of overflowing on small screens or large fonts.
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.authCardFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.authCardBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.cloud_off_rounded,
                        color: AppColors.authTextSecondary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No pudimos iniciar Luma',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Reintentar',
                    icon: Icons.refresh_rounded,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
