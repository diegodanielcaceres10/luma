import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/invoice.dart';
import '../utils/month_names.dart';
import '../view_models/invoice_view_model.dart';
import '../widgets/pay_invoice_dialog.dart';

enum _InvoiceAction { edit, pay, cancel }

/// Invoice detail. Edit, pay and cancel are only offered while the invoice
/// is pending.
class InvoiceViewScreen extends StatelessWidget {
  final String userId;
  final Invoice invoice;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final AccountViewModel accountViewModel;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onBack;

  const InvoiceViewScreen({
    super.key,
    required this.userId,
    required this.invoice,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.accountViewModel,
    required this.currency,
    required this.onEdit,
    required this.onBack,
  });

  // The route guard resolves the invoice once, so look it up again to
  // reflect changes made after the screen was opened.
  Invoice _currentInvoice() {
    for (final i in invoiceViewModel.invoices) {
      if (i.id == invoice.id) return i;
    }
    return invoice;
  }

  Future<void> _confirmCancel(BuildContext context, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        title: const Text(
          '¿Cancelar factura?',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'La factura quedará marcada como cancelada. Esta acción no se '
          'puede deshacer.',
          style: TextStyle(color: AppColors.authTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Volver',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Cancelar factura',
              style: TextStyle(
                color: AppColors.authExpense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await invoiceViewModel.cancelInvoice(invoice.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invoiceViewModel.errorMessage ?? 'No se pudo cancelar la factura.',
          ),
        ),
      );
    }
  }

  Future<void> _payInvoice(
    BuildContext context, {
    required Invoice invoice,
    required String serviceName,
    required Category? category,
  }) async {
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El servicio no tiene categoría o fue eliminado; no se puede '
            'registrar el pago.',
          ),
        ),
      );
      return;
    }

    final result = await showDialog<PayInvoiceResult>(
      context: context,
      builder: (_) => PayInvoiceDialog(
        invoice: invoice,
        serviceName: serviceName,
        category: category,
        accounts: accountViewModel.activeAccounts,
        currency: currency,
      ),
    );

    if (result == null) return;

    final ok = await invoiceViewModel.payInvoice(
      invoice: invoice,
      userId: userId,
      accountId: result.accountId,
      categoryId: category.id,
      amount: result.amount,
      description: 'Factura · $serviceName',
      date: result.date,
    );

    // The account balance changed on the server together with the expense
    // transaction; reload accounts so the new balance is shown.
    if (ok) await accountViewModel.loadAccounts();

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invoiceViewModel.errorMessage ?? 'No se pudo registrar el pago.',
          ),
        ),
      );
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          invoiceViewModel,
          serviceViewModel,
          categoryViewModel,
        ]),
        builder: (context, _) {
          final current = _currentInvoice();
          final service = serviceViewModel.serviceById(current.serviceId);
          final serviceName = service?.name ?? 'Servicio eliminado';
          final category = categoryViewModel.categoryById(service?.categoryId);
          final isBusy = invoiceViewModel.isCancelling(current.id) ||
              invoiceViewModel.isPaying(current.id);

          final badgeColor = current.cancelled
              ? AppColors.authTextFooter
              : current.paid
                  ? AppColors.authIncome
                  : AppColors.authExpense;
          final badgeLabel = current.cancelled
              ? 'Cancelada'
              : current.paid
                  ? 'Pagada'
                  : 'Pendiente';

          final details = <_DetailRow>[
            _DetailRow(
              label: 'Estado',
              value: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
            _DetailRow(
              label: 'Monto',
              value: Text(
                formatCurrency(current.amount, currency),
                style: _valueStyle,
              ),
            ),
            _DetailRow(
              label: 'Período',
              value: Text(
                '${kMonthNames[current.month - 1]} ${current.year}',
                style: _valueStyle,
              ),
            ),
            _DetailRow(
              label: 'Vencimiento',
              value: Text(
                current.dueDate != null
                    ? _formatDate(current.dueDate!)
                    : 'Sin vencimiento',
                style: _valueStyle,
              ),
            ),
            _DetailRow(
              label: 'Categoría',
              value: category == null
                  ? const Text('Sin categoría', style: _valueStyle)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorFromHex(
                              category.color,
                              fallback: AppColors.authTextFooter,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(category.name, style: _valueStyle),
                      ],
                    ),
            ),
            if (current.paid && current.paidAt != null)
              _DetailRow(
                label: 'Fecha de pago',
                value: Text(_formatDate(current.paidAt!), style: _valueStyle),
              ),
            if (current.cancelled && current.cancelledAt != null)
              _DetailRow(
                label: 'Fecha de cancelación',
                value: Text(
                  _formatDate(current.cancelledAt!),
                  style: _valueStyle,
                ),
              ),
          ];

          return Column(
            children: [
              if (isBusy)
                const LinearProgressIndicator(
                  backgroundColor: AppColors.authCardBorder,
                  color: AppColors.authAccent,
                  minHeight: 3,
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    ScreenHeader(
                      title: serviceName,
                      size: ScreenHeaderSize.compact,
                      onBack: onBack,
                      action: current.isPending
                          ? HeaderMenuButton<_InvoiceAction>(
                              enabled: !isBusy,
                              items: const [
                                HeaderMenuItem(
                                  value: _InvoiceAction.edit,
                                  label: 'Editar factura',
                                  icon: Icons.edit_rounded,
                                ),
                                HeaderMenuItem(
                                  value: _InvoiceAction.pay,
                                  label: 'Registrar pago',
                                  icon: Icons.check_circle_outline_rounded,
                                ),
                                HeaderMenuItem(
                                  value: _InvoiceAction.cancel,
                                  label: 'Cancelar factura',
                                  icon: Icons.close_rounded,
                                  destructive: true,
                                ),
                              ],
                              onSelected: (action) {
                                switch (action) {
                                  case _InvoiceAction.edit:
                                    onEdit();
                                  case _InvoiceAction.pay:
                                    _payInvoice(
                                      context,
                                      invoice: current,
                                      serviceName: serviceName,
                                      category: category,
                                    );
                                  case _InvoiceAction.cancel:
                                    _confirmCancel(context, current);
                                }
                              },
                            )
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.authCardFill,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.authCardBorder),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < details.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: AppColors.authCardBorder,
                              ),
                            details[i],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const _valueStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: AppColors.authTextPrimary,
);

class _DetailRow extends StatelessWidget {
  final String label;
  final Widget value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          value,
        ],
      ),
    );
  }
}
