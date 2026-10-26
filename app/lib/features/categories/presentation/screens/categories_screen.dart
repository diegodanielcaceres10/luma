import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';

class CategoriesScreen extends StatelessWidget {
  final CategoryViewModel categoryViewModel;

  final ValueChanged<Category> onOpenView;

  /// Opens the create form.
  final VoidCallback onOpenForm;

  final VoidCallback? onBack;

  const CategoriesScreen({
    super.key,
    required this.categoryViewModel,
    required this.onOpenView,
    required this.onOpenForm,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: categoryViewModel,
        builder: (context, _) {
          final expenses = categoryViewModel.byType('expense');
          final incomes = categoryViewModel.byType('income');
          final isInitialLoad = categoryViewModel.isLoading &&
              categoryViewModel.categories.isEmpty;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScreenHeader(
                    title: 'Categorías',
                    subtitle: 'Clasifica tus gastos e ingresos para un mejor '
                        'control financiero.',
                    size: ScreenHeaderSize.compact,
                    onBack: onBack,
                    action: HeaderAddButton(
                      tooltip: 'Nueva categoría',
                      onPressed: onOpenForm,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isInitialLoad)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.authAccent,
                        ),
                      ),
                    )
                  else if (expenses.isEmpty && incomes.isEmpty)
                    const _EmptyCategoriesCard()
                  else ...[
                    if (expenses.isNotEmpty) ...[
                      _SectionLabel('Gastos (${expenses.length})'),
                      _CategoryGroup(categories: expenses, onTap: onOpenView),
                      const SizedBox(height: 24),
                    ],
                    if (incomes.isNotEmpty) ...[
                      _SectionLabel('Ingresos (${incomes.length})'),
                      _CategoryGroup(categories: incomes, onTap: onOpenView),
                    ],
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
      padding: const EdgeInsets.only(left: 4, bottom: 10),
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

class _EmptyCategoriesCard extends StatelessWidget {
  const _EmptyCategoriesCard();

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
              Icons.category_outlined,
              size: 28,
              color: AppColors.authAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Todavía no hay categorías.\nTocá + para crear la primera.',
            textAlign: TextAlign.center,
            style: AppTextStyles.authSubtitle,
          ),
        ],
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
    return Container(
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
    final catColor = colorFromHex(
      category.color,
      fallback: AppColors.authTextFooter,
    );

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: catColor.withValues(alpha: 0.45),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                        if (category.hasBudget) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 13,
                                color:
                                    AppColors.authAccent.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Con presupuesto',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.authTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
