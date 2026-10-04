import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/currency_format.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../invoices/data/models/invoice.dart';
import '../../../../services/presentation/view_models/service_view_model.dart';
import 'pending_movement.dart';

class SelectPendingInvoiceSheet extends StatelessWidget {
  final List<Invoice> invoices;
  final ServiceViewModel serviceViewModel;
  final String currency;

  const SelectPendingInvoiceSheet({
    super.key,
    required this.invoices,
    required this.serviceViewModel,
    required this.currency,
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
            const Text(
              'Facturas pendientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No hay facturas pendientes para pagar.',
                  style: TextStyle(color: AppColors.authTextSecondary),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.authCardBorder,
                    height: 1,
                  ),
                  itemBuilder: (context, i) {
                    final invoice = invoices[i];
                    final service =
                        serviceViewModel.serviceById(invoice.serviceId);
                    final serviceName = service?.name ?? 'Servicio eliminado';
                    final dueDate = invoice.dueDate;
                    final monthYear =
                        '${kMonthAbbreviations[invoice.month - 1]} '
                        '${invoice.year}';
                    return InkWell(
                      onTap: () => Navigator.of(context).pop(invoice),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    serviceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.authTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dueDate == null
                                        ? monthYear
                                        : '$monthYear · vence '
                                            '${formatDate(dueDate)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.authTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatCurrency(invoice.amount, currency),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.authTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
