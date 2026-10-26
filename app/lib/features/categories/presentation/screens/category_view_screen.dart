import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';
import '../widgets/category_trend_section.dart';

enum _CategoryAction { edit }

class CategoryViewScreen extends StatelessWidget {
  final Category category;
  final CategoryViewModel categoryViewModel;
  final TransactionViewModel transactionViewModel;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onBack;

  const CategoryViewScreen({
    super.key,
    required this.category,
    required this.categoryViewModel,
    required this.transactionViewModel,
    required this.currency,
    required this.onEdit,
    required this.onBack,
  });

  // The route guard resolves the category once, so look it up again to
  // reflect changes made after the screen was opened.
  Category _currentCategory() =>
      categoryViewModel.categoryById(category.id) ?? category;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: categoryViewModel,
        builder: (context, _) {
          final current = _currentCategory();
          final isExpense = current.type == 'expense';
          final budget = current.hasBudget ? current.budgetAmount : null;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScreenHeader(
                    title: current.name,
                    subtitle: 'Detalles y métricas de la categoría',
                    size: ScreenHeaderSize.compact,
                    onBack: onBack,
                    action: HeaderMenuButton<_CategoryAction>(
                      items: const [
                        HeaderMenuItem(
                          value: _CategoryAction.edit,
                          label: 'Editar categoría',
                          icon: Icons.edit_rounded,
                        ),
                      ],
                      onSelected: (action) => switch (action) {
                        _CategoryAction.edit => onEdit(),
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HeroCategoryCard(
                    category: current,
                    currency: currency,
                    budget: budget,
                    isExpense: isExpense,
                  ),
                  const SizedBox(height: 14),
                  _QuickActionsRow(onEdit: onEdit),
                  const SizedBox(height: 20),
                  CategoryTrendSection(
                    category: current,
                    currency: currency,
                    transactionViewModel: transactionViewModel,
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

class _HeroCategoryCard extends StatelessWidget {
  final Category category;
  final String currency;
  final double? budget;
  final bool isExpense;

  const _HeroCategoryCard({
    required this.category,
    required this.currency,
    required this.budget,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = colorFromHex(
      category.color,
      fallback: AppColors.authTextFooter,
    );
    final typeColor =
        isExpense ? AppColors.authExpense : AppColors.authIncome;

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
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: catColor.withValues(alpha: 0.32),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
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
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpense
                                ? Icons.trending_down_rounded
                                : Icons.trending_up_rounded,
                            size: 13,
                            color: typeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpense ? 'Gasto' : 'Ingreso',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
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
          if (isExpense) ...[
            const SizedBox(height: 18),
            if (budget != null) ...[
              const Text(
                'Presupuesto mensual',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: AppColors.authTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency(budget!, currency),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.authTextPrimary,
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.authCardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 16,
                      color: AppColors.authTextSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sin presupuesto mensual asignado',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.authCardBorder),
          const SizedBox(height: 4),
          _DetailRow(
            label: 'Tipo',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpense
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  size: 16,
                  color: typeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isExpense ? 'Gasto' : 'Ingreso',
                  style: _valueStyle.copyWith(color: typeColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.authCardBorder),
          _DetailRow(
            label: 'Color',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
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
                if (category.color != null) ...[
                  const SizedBox(width: 8),
                  Text(category.color!.toUpperCase(), style: _valueStyle),
                ],
              ],
            ),
          ),
          if (isExpense) ...[
            const Divider(height: 1, color: AppColors.authCardBorder),
            _DetailRow(
              label: 'Presupuesto mensual',
              value: Text(
                budget != null
                    ? formatCurrency(budget!, currency)
                    : 'Sin presupuesto',
                style: _valueStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onEdit;

  const _QuickActionsRow({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.authAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.authAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.authAccent,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Editar categoría',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
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
