import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../data/models/invoice.dart';
import '../view_models/invoice_view_model.dart';

/// Contenido de la pestaña "Facturas". No tiene Scaffold propio — vive
/// dentro del Scaffold del HomeShell, que es quien pone el header (con el
/// botón "+" para crear) y el bottomNavigationBar.
///
/// Además de crear facturas, desde acá se puede cancelar una factura
/// pendiente — cerrar su flujo sin pasar por un pago. El pago en sí
/// (marcarla como pagada, asociarla a una transacción) se agrega en una
/// etapa futura.
class InvoicesTab extends StatelessWidget {
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;

  const InvoicesTab({
    super.key,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.categoryViewModel,
  });

  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  Future<void> _confirmCancel(BuildContext context, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cancelar factura?'),
        content: const Text(
          'La factura quedará marcada como cancelada. Esta acción no se '
          'puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar factura'),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge(
            [invoiceViewModel, serviceViewModel, categoryViewModel]),
        builder: (context, _) {
          if (invoiceViewModel.isLoading &&
              invoiceViewModel.invoices.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          final invoices = invoiceViewModel.invoices;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Facturas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (invoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'Todavía no hay facturas.\nTocá + para crear la primera.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSubtitle,
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.authCardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.authCardBorder),
                  ),
                  child: Column(
                    children: List.generate(invoices.length, (i) {
                      final invoice = invoices[i];
                      final service =
                          serviceViewModel.serviceById(invoice.serviceId);
                      return _InvoiceRow(
                        invoice: invoice,
                        serviceName: service?.name ?? 'Servicio eliminado',
                        category:
                            categoryViewModel.categoryById(service?.categoryId),
                        monthLabel: _monthNames[invoice.month - 1],
                        showDivider: i != invoices.length - 1,
                        isCancelling: invoiceViewModel.isCancelling(invoice.id),
                        onCancel: () => _confirmCancel(context, invoice),
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Invoice invoice;
  final String serviceName;
  final Category? category;
  final String monthLabel;
  final bool showDivider;
  final bool isCancelling;
  final VoidCallback onCancel;

  const _InvoiceRow({
    required this.invoice,
    required this.serviceName,
    required this.category,
    required this.monthLabel,
    required this.showDivider,
    required this.isCancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        colorFromHex(category?.color, fallback: AppColors.authAccent);

    final badgeColor = invoice.cancelled
        ? AppColors.authTextFooter
        : invoice.paid
            ? AppColors.authIncome
            : AppColors.authExpense;
    final badgeLabel = invoice.cancelled
        ? 'Cancelada'
        : invoice.paid
            ? 'Pagada'
            : 'Pendiente';

    final dueDate = invoice.dueDate;
    final subtitleParts = <String>[
      '$monthLabel ${invoice.year}',
      formatCurrency(invoice.amount, 'EUR'),
      if (dueDate != null)
        'vence el ${dueDate.day.toString().padLeft(2, '0')}/'
            '${dueDate.month.toString().padLeft(2, '0')}',
    ];

    return Column(
      children: [
        Opacity(
          opacity: invoice.cancelled ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.85),
                  child: Icon(
                    category != null
                        ? iconFromName(category!.icon)
                        : Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
                if (invoice.isPending) ...[
                  const SizedBox(width: 4),
                  isCancelling
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.authTextSecondary,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.authTextSecondary,
                          ),
                          tooltip: 'Cancelar factura',
                          onPressed: onCancel,
                        ),
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}
