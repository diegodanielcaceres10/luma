import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_text_styles.dart';
import '../../../../../core/widgets/buttons/text_action_button.dart';

class TransactionsFilterSectionLabel extends StatelessWidget {
  final String label;

  const TransactionsFilterSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.authTextFooter,
      ),
    );
  }
}

class TransactionsEmptyFilteredState extends StatelessWidget {
  final VoidCallback? onClear;

  const TransactionsEmptyFilteredState({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.authTextSecondary,
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No hay movimientos con estos filtros.',
            textAlign: TextAlign.center,
            style: AppTextStyles.authSubtitle,
          ),
          if (onClear != null) ...[
            const SizedBox(height: 14),
            TextActionButton(
              label: 'Quitar filtros',
              color: AppColors.authAccent,
              fontWeight: FontWeight.w600,
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }
}
