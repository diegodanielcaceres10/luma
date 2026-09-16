import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';

/// Contenido de la pestaña "Presupuestos". No tiene Scaffold propio — vive
/// dentro del Scaffold del HomeShell, que es quien pone el header (con el
/// botón "+" para crear) y el bottomNavigationBar.
///
/// El presupuesto ya no vive en una tabla separada: es un dato de la propia
/// categoría (`has_budget` + `budget_amount`). Esta pestaña es un filtro
/// sobre [CategoryViewModel.budgetedCategories].
class BudgetsTab extends StatelessWidget {
  final CategoryViewModel categoryViewModel;
  final String currency;
  final ValueChanged<Category> onEdit;

  const BudgetsTab({
    super.key,
    required this.categoryViewModel,
    required this.currency,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: categoryViewModel,
        builder: (context, _) {
          if (categoryViewModel.isLoading &&
              categoryViewModel.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          final budgets = categoryViewModel.budgetedCategories;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Presupuestos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (budgets.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'Todavía no hay presupuestos.\nTocá + para crear el primero.',
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
                    children: List.generate(budgets.length, (i) {
                      final category = budgets[i];
                      return _BudgetRow(
                        category: category,
                        currency: currency,
                        onTap: () => onEdit(category),
                        showDivider: i != budgets.length - 1,
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

class _BudgetRow extends StatelessWidget {
  final Category category;
  final String currency;
  final VoidCallback onTap;
  final bool showDivider;

  const _BudgetRow({
    required this.category,
    required this.currency,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.color, fallback: AppColors.authAccent);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.85),
                  child: Icon(iconFromName(category.icon),
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                ),
                Text(
                  formatCurrency(category.budgetAmount ?? 0, currency),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.authTextFooter),
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
