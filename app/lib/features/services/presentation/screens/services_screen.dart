import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/layout/screen_header.dart';
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
          final activeServices = services.where((s) => s.isActive).toList();
          final totalMonthly = activeServices.fold<double>(
            0,
            (sum, s) => sum + s.approximateAmount,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScreenHeader(
                    title: 'Servicios',
                    subtitle: 'Supervisa tus suscripciones, costos fijos y '
                        'vencimientos.',
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
                  const SizedBox(height: 20),
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
                    _EmptyServicesCard()
                  else ...[
                    _TotalServicesCard(
                      isLoading: serviceViewModel.isLoading,
                      total: totalMonthly,
                      activeCount: activeServices.length,
                      totalCount: services.length,
                      currency: currency,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('Tus servicios (${services.length})'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.authCardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.authCardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(services.length, (i) {
                          final service = services[i];
                          return _ServiceRow(
                            service: service,
                            category: categoryViewModel
                                .categoryById(service.categoryId),
                            currency: currency,
                            onTap: () => onOpenView(service),
                            showDivider: i != services.length - 1,
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.authTextSecondary,
        ),
      ),
    );
  }
}

class _EmptyServicesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: AppColors.authAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Todavía no hay servicios.\nTocá + para crear el primero.',
            textAlign: TextAlign.center,
            style: AppTextStyles.authSubtitle,
          ),
        ],
      ),
    );
  }
}

class _TotalServicesCard extends StatelessWidget {
  final bool isLoading;
  final double total;
  final int activeCount;
  final int totalCount;
  final String currency;

  const _TotalServicesCard({
    required this.isLoading,
    required this.total,
    required this.activeCount,
    required this.totalCount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.authAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gasto mensual estimado',
                  style: TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.authAccent,
                          ),
                        ),
                      )
                    : Text(
                        formatCurrency(total, currency),
                        style: const TextStyle(
                          color: AppColors.authTextPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                const SizedBox(height: 3),
                Text(
                  '$activeCount activos · $totalCount en total',
                  style: const TextStyle(
                    color: AppColors.authTextFooter,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final catColor = category?.color != null
        ? colorFromHex(category!.color)
        : AppColors.authAccent;

    final subtitleParts = <String>[
      if (service.dueDay != null) 'Vence el día ${service.dueDay}',
      if (category != null) category!.name,
      if (!isActive) 'Inactivo',
    ];

    return Column(
      children: [
        Opacity(
          opacity: isActive ? 1.0 : 0.55,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: catColor.withValues(
                          alpha: isActive ? 0.14 : 0.06,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: catColor.withValues(
                            alpha: isActive ? 0.32 : 0.15,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: isActive
                            ? catColor
                            : AppColors.authTextSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextPrimary,
                            ),
                          ),
                          if (subtitleParts.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitleParts.join(' · '),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isActive
                                    ? AppColors.authTextSecondary
                                    : AppColors.authTextFooter,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(service.approximateAmount, currency),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.authTextPrimary
                                : AppColors.authTextFooter,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.authTextFooter,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
            color: AppColors.authCardBorder,
          ),
      ],
    );
  }
}
