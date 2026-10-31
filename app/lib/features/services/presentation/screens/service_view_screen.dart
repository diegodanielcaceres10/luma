import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../data/models/service.dart';
import '../view_models/service_view_model.dart';
import '../widgets/service_trend_section.dart';

enum _ServiceAction { edit }

class ServiceViewScreen extends StatelessWidget {
  final Service service;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final InvoiceViewModel invoiceViewModel;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onBack;

  const ServiceViewScreen({
    super.key,
    required this.service,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.invoiceViewModel,
    required this.currency,
    required this.onEdit,
    required this.onBack,
  });

  // The route guard resolves the service once, so look it up again to
  // reflect changes made after the screen was opened.
  Service _currentService() =>
      serviceViewModel.serviceById(service.id) ?? service;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          serviceViewModel,
          categoryViewModel,
          invoiceViewModel,
        ]),
        builder: (context, _) {
          final current = _currentService();
          final category = categoryViewModel.categoryById(current.categoryId);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScreenHeader(
                    title: current.name,
                    subtitle: 'Detalles y evolución histórica del servicio.',
                    size: ScreenHeaderSize.compact,
                    onBack: onBack,
                    action: HeaderMenuButton<_ServiceAction>(
                      items: const [
                        HeaderMenuItem(
                          value: _ServiceAction.edit,
                          label: 'Editar servicio',
                          icon: Icons.edit_rounded,
                        ),
                      ],
                      onSelected: (action) => switch (action) {
                        _ServiceAction.edit => onEdit(),
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HeroServiceCard(
                    service: current,
                    category: category,
                    currency: currency,
                    onToggleActive: (value) => serviceViewModel.toggleActive(
                      current.id,
                      value,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ServiceTrendSection(
                    service: current,
                    currency: currency,
                    color: colorFromHex(
                      category?.color,
                      fallback: AppColors.authAccent,
                    ),
                    invoiceViewModel: invoiceViewModel,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroServiceCard extends StatelessWidget {
  final Service service;
  final Category? category;
  final String currency;
  final ValueChanged<bool> onToggleActive;

  const _HeroServiceCard({
    required this.service,
    required this.category,
    required this.currency,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;
    final catColor = category?.color != null
        ? colorFromHex(category!.color)
        : AppColors.authAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: isActive ? 0.14 : 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: catColor.withValues(alpha: isActive ? 0.32 : 0.15),
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 24,
                  color: isActive
                      ? catColor
                      : AppColors.authTextSecondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.authAccent.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? AppColors.authAccent.withValues(alpha: 0.28)
                              : AppColors.authCardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_rounded,
                            size: 13,
                            color: isActive
                                ? AppColors.authAccent
                                : AppColors.authTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Servicio activo' : 'Servicio inactivo',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppColors.authAccent
                                  : AppColors.authTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Monto aproximado',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.authTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency(service.approximateAmount, currency),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.authCardBorder),
          const SizedBox(height: 4),
          _DetailRow(
            label: 'Día de vencimiento',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (service.dueDay != null) ...[
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.authAccent,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  service.dueDay != null
                      ? 'Día ${service.dueDay}'
                      : 'Sin definir',
                  style: _valueStyle,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.authCardBorder),
          _DetailRow(
            label: 'Categoría',
            value: category == null
                ? const Text('Sin categoría', style: _valueStyle)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: catColor,
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withValues(alpha: 0.45),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(category!.name, style: _valueStyle),
                    ],
                  ),
          ),
          const Divider(height: 1, color: AppColors.authCardBorder),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del servicio',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? 'Incluido en la generación de facturas'
                            : 'Pausado temporalmente',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.authTextFooter,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeTrackColor: AppColors.authAccent,
                  onChanged: onToggleActive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _valueStyle = TextStyle(
  fontSize: 14.5,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
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
