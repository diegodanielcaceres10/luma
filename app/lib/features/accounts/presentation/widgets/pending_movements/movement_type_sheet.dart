import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import 'pending_movement.dart';

class MovementTypeSheet extends StatelessWidget {
  final String title;

  /// When set (editing), replaces the Expense/Income options with a single
  /// "Categorizar" one that resolves to this kind.
  final PendingMovementKind? categorizeKind;

  /// Whether the "Factura de servicio" option is shown.
  final bool offerInvoice;

  const MovementTypeSheet({
    super.key,
    this.title = 'Agregar movimiento',
    this.categorizeKind,
    this.offerInvoice = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.authCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (categorizeKind != null)
              _MovementTypeOption(
                icon: Icons.sell_outlined,
                iconColor: AppColors.authAccent,
                label: 'Categorizar',
                onTap: () => Navigator.of(context).pop(categorizeKind),
              ),
            if (categorizeKind == null)
              _MovementTypeOption(
                icon: Icons.arrow_upward_rounded,
                iconColor: AppColors.authExpense,
                label: 'Gasto',
                onTap: () =>
                    Navigator.of(context).pop(PendingMovementKind.expense),
              ),
            if (categorizeKind == null)
              _MovementTypeOption(
                icon: Icons.arrow_downward_rounded,
                iconColor: AppColors.authIncome,
                label: 'Ingreso',
                onTap: () =>
                    Navigator.of(context).pop(PendingMovementKind.income),
              ),
            if (offerInvoice)
              _MovementTypeOption(
                icon: Icons.request_page_outlined,
                iconColor: AppColors.authInvoice,
                label: 'Factura de servicio',
                onTap: () =>
                    Navigator.of(context).pop(PendingMovementKind.invoice),
              ),
            _MovementTypeOption(
              icon: Icons.swap_horiz_rounded,
              iconColor: AppColors.authTransfer,
              label: 'Transferencia',
              onTap: () =>
                  Navigator.of(context).pop(PendingMovementKind.transfer),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementTypeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MovementTypeOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.18),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
