import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';

/// Contenido de la pestaña "Categorías". No tiene Scaffold propio — vive
/// dentro del Scaffold del HomeShell, que es quien pone el header (con el
/// botón "+" para crear) y el bottomNavigationBar.
class CategoriesTab extends StatelessWidget {
  final CategoryViewModel categoryViewModel;
  final ValueChanged<Category> onEdit;

  const CategoriesTab({
    super.key,
    required this.categoryViewModel,
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

          final expenses = categoryViewModel.byType('expense');
          final incomes = categoryViewModel.byType('income');

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (expenses.isEmpty && incomes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'Todavía no hay categorías.\nTocá + para crear la primera.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSubtitle,
                  ),
                )
              else ...[
                if (expenses.isNotEmpty) ...[
                  const _SectionLabel('Gastos'),
                  _CategoryGroup(categories: expenses, onTap: onEdit),
                  const SizedBox(height: 20),
                ],
                if (incomes.isNotEmpty) ...[
                  const _SectionLabel('Ingresos'),
                  _CategoryGroup(categories: incomes, onTap: onEdit),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.authTextSecondary,
        ),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<Category> onTap;

  const _CategoryGroup({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: List.generate(categories.length, (i) {
          final category = categories[i];
          return _CategoryRow(
            category: category,
            onTap: () => onTap(category),
            showDivider: i != categories.length - 1,
          );
        }),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final bool showDivider;

  const _CategoryRow({
    required this.category,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
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
