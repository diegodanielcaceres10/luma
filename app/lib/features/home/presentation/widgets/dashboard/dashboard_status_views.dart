import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';

/// Centered spinner while the dashboard's initial data arrives.
class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.authAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown if the accounts could not be loaded, so the spinner doesn't spin
/// forever or the "no accounts" card show up by mistake.
class DashboardLoadErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const DashboardLoadErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
                'No pudimos cargar tus datos',
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
    );
  }
}

class DashboardNoAccountsCard extends StatelessWidget {
  final VoidCallback onGoToAccounts;

  const DashboardNoAccountsCard({super.key, required this.onGoToAccounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.authAccent.withValues(alpha: 0.15),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.authAccent,
              size: 38,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Creá tu primera cuenta',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para empezar a registrar tus movimientos\nnecesitás al menos una cuenta activa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.authTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Crear cuenta',
              icon: Icons.add_rounded,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: onGoToAccounts,
            ),
          ),
        ],
      ),
    );
  }
}
