import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../data/models/service.dart';
import '../view_models/service_view_model.dart';

/// Contenido de la pestaña "Servicios". Es una ruta de primer nivel del
/// drawer sin AppBar propio (ver RoutedScreenScaffold): vive dentro del
/// Scaffold del AppShellScreen, que pone el header y el
/// bottomNavigationBar. El "+" para crear va alineado con el título de
/// acá abajo, no en ninguna barra superior.
class ServicesTab extends StatelessWidget {
  final ServiceViewModel serviceViewModel;
  final CategoryViewModel categoryViewModel;
  final ValueChanged<Service> onEdit;

  /// Abre el formulario de alta ("+" del título).
  final VoidCallback onAdd;

  const ServicesTab({
    super.key,
    required this.serviceViewModel,
    required this.categoryViewModel,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([serviceViewModel, categoryViewModel]),
        builder: (context, _) {
          if (serviceViewModel.isLoading && serviceViewModel.services.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          final services = serviceViewModel.services;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  const Text(
                    'Servicios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.authTextPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (services.isEmpty)
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
                        onTap: () => onEdit(service),
                        onActiveChanged: (value) =>
                            serviceViewModel.toggleActive(service.id, value),
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
  final VoidCallback onTap;
  final ValueChanged<bool> onActiveChanged;
  final bool showDivider;

  const _ServiceRow({
    required this.service,
    required this.category,
    required this.onTap,
    required this.onActiveChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;

    final subtitleParts = <String>[
      formatCurrency(service.approximateAmount, 'EUR'),
      if (service.dueDay != null) 'vence el día ${service.dueDay}',
      if (category != null) category!.name,
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        activeTrackColor: AppColors.authAccent,
                        onChanged: onActiveChanged,
                      ),
                      Text(
                        isActive ? 'Activo' : 'Inactivo',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.authTextFooter,
                        ),
                      ),
                    ],
                  ),
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
