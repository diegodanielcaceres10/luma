import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../data/models/transaction_entry.dart';

/// What the user picked from the movement actions sheet.
enum MovementAction {
  edit,
  markTransfer,
  unmarkTransfer,
  linkInvoice,
  unlinkInvoice,
  delete,
}

/// Opens the actions sheet of [movement]. Resolves to the chosen action, or
/// null if the sheet was dismissed.
///
/// [isServicePayment] tells that the movement is the payment of a paid
/// invoice; it can't be flagged as a transfer until it is unlinked.
Future<MovementAction?> showMovementActionsSheet(
  BuildContext context, {
  required TransactionEntry movement,
  required bool isServicePayment,
}) {
  return showModalBottomSheet<MovementAction>(
    context: context,
    backgroundColor: AppColors.authBackgroundBottom,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => MovementActionsSheet(
      movement: movement,
      isServicePayment: isServicePayment,
    ),
  );
}

class MovementActionsSheet extends StatelessWidget {
  final TransactionEntry movement;
  final bool isServicePayment;

  const MovementActionsSheet({
    super.key,
    required this.movement,
    required this.isServicePayment,
  });

  String get _title => movement.description?.isNotEmpty == true
      ? movement.description!
      : movement.category.name;

  /// Transfers and service payments exclude each other: the user has to undo
  /// one before applying the other.
  bool get _canToggleTransfer => movement.isTransfer || !isServicePayment;

  /// Only regular expenses can pay an invoice.
  bool get _canLinkInvoice => !movement.isTransfer && !movement.isIncome;

  @override
  Widget build(BuildContext context) {
    void pick(MovementAction action) => Navigator.of(context).pop(action);

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
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _ActionOption(
              icon: Icons.edit_outlined,
              iconColor: AppColors.authAccent,
              label: 'Editar',
              onTap: () => pick(MovementAction.edit),
            ),
            if (_canToggleTransfer)
              _ActionOption(
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.authTransfer,
                label: movement.isTransfer
                    ? 'Quitar marca de transferencia'
                    : 'Marcar como transferencia',
                onTap: () => pick(
                  movement.isTransfer
                      ? MovementAction.unmarkTransfer
                      : MovementAction.markTransfer,
                ),
              ),
            if (isServicePayment)
              _ActionOption(
                icon: Icons.link_off_rounded,
                iconColor: AppColors.authInvoice,
                label: 'Desvincular del servicio',
                onTap: () => pick(MovementAction.unlinkInvoice),
              )
            else if (_canLinkInvoice)
              _ActionOption(
                icon: Icons.request_page_outlined,
                iconColor: AppColors.authInvoice,
                label: 'Vincular a factura pendiente',
                onTap: () => pick(MovementAction.linkInvoice),
              ),
            _ActionOption(
              icon: Icons.delete_outline,
              iconColor: AppColors.authExpense,
              label: 'Eliminar',
              labelColor: AppColors.authExpense,
              onTap: () => pick(MovementAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  const _ActionOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor = AppColors.authTextPrimary,
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
