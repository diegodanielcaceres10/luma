import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/primary_button.dart';

/// Centered spinner while the dashboard's initial data arrives.
class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.authAccent,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.authTextSecondary,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar tus datos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.authAccent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Creá tu primera cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
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
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.authAccent,
                foregroundColor: AppColors.authBackgroundBottom,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onGoToAccounts,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear cuenta'),
            ),
          ),
        ],
      ),
    );
  }
}
