import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../categories/data/models/category.dart';
import '../../../auth/presentation/view_models/preferences_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../notifications/presentation/widgets/notifications_hint.dart';
import '../../data/models/service.dart';
import '../view_models/service_view_model.dart';

class ServicesScreen extends StatelessWidget {
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final PreferencesViewModel preferencesViewModel;
  final String currency;

  final ValueChanged<Service> onOpenView;

  /// Opens the create form.
  final VoidCallback onOpenForm;

  /// Opens Preferencias, from the notifications hint.
  final VoidCallback onOpenPreferences;

  final VoidCallback? onBack;

  const ServicesScreen({
    super.key,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.preferencesViewModel,
    required this.currency,
    required this.onOpenView,
    required this.onOpenForm,
    required this.onOpenPreferences,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([serviceViewModel, categoryViewModel]),
        builder: (context, _) {
          final services = serviceViewModel.services;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                title: 'Servicios',
                size: ScreenHeaderSize.compact,
                onBack: onBack,
                action: HeaderAddButton(
                  tooltip: 'Nuevo servicio',
                  onPressed: onOpenForm,
                ),
              ),
              const SizedBox(height: 12),
              NotificationsHint(
                preferencesViewModel: preferencesViewModel,
                onOpenPreferences: onOpenPreferences,
              ),
              const SizedBox(height: 16),
              if (serviceViewModel.isLoading && services.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
                  ),
                )
              else if (services.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'Todavía no hay servicios.\nTocá + para crear el primero.',
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
                    children: List.generate(services.length, (i) {
                      final service = services[i];
                      return _ServiceRow(
                        service: service,
                        category:
                            categoryViewModel.categoryById(service.categoryId),
                        currency: currency,
                        onTap: () => onOpenView(service),
                        showDivider: i != services.length - 1,
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

class _ServiceRow extends StatelessWidget {
  final Service service;
  final Category? category;
  final String currency;
  final VoidCallback onTap;
  final bool showDivider;

  const _ServiceRow({
    required this.service,
    required this.category,
    required this.currency,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;

    final subtitleParts = <String>[
      formatCurrency(service.approximateAmount, currency),
      if (service.dueDay != null) 'vence el día ${service.dueDay}',
      if (category != null) category!.name,
      if (!isActive) 'Inactivo',
    ];

    return Column(
      children: [
        Opacity(
          opacity: isActive ? 1 : 0.5,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
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
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.authTextFooter),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}
