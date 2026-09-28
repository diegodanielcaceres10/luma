import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/service.dart';
import '../view_models/service_view_model.dart';

enum _ServiceAction { edit }

class ServiceViewScreen extends StatelessWidget {
  final Service service;
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onBack;

  const ServiceViewScreen({
    super.key,
    required this.service,
    required this.serviceViewModel,
    required this.categoryViewModel,
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
        listenable: Listenable.merge([serviceViewModel, categoryViewModel]),
        builder: (context, _) {
          final current = _currentService();
          final category = categoryViewModel.categoryById(current.categoryId);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                title: current.name,
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
                    _DetailRow(
                      label: 'Monto aproximado',
                      value: Text(
                        formatCurrency(current.approximateAmount, currency),
                        style: _valueStyle,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.authCardBorder),
                    _DetailRow(
                      label: 'Día de vencimiento',
                      value: Text(
                        current.dueDay != null
                            ? 'Día ${current.dueDay}'
                            : 'Sin definir',
                        style: _valueStyle,
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
                    const Divider(height: 1, color: AppColors.authCardBorder),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            current.isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_rounded,
                            size: 18,
                            color: current.isActive
                                ? AppColors.authAccent
                                : AppColors.authTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            current.isActive
                                ? 'Servicio activo'
                                : 'Servicio inactivo',
                            style: const TextStyle(
                              color: AppColors.authTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: current.isActive,
                            activeTrackColor: AppColors.authAccent,
                            onChanged: (value) => serviceViewModel.toggleActive(
                              current.id,
                              value,
                            ),
                          ),
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
