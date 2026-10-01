import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
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
          final typeColor =
              isExpense ? AppColors.authExpense : AppColors.authIncome;
          final budget = current.hasBudget ? current.budgetAmount : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                title: current.name,
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
                      label: 'Tipo',
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpense
                                ? Icons.trending_down_rounded
                                : Icons.trending_up_rounded,
                            size: 18,
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
                              color: colorFromHex(
                                current.color,
                                fallback: AppColors.authTextFooter,
                              ),
                            ),
                          ),
                          if (current.color != null) ...[
                            const SizedBox(width: 8),
                            Text(current.color!.toUpperCase(),
                                style: _valueStyle),
                          ],
                        ],
                      ),
                    ),
                    if (isExpense) ...[
                      const Divider(
                          height: 1, color: AppColors.authCardBorder),
                      _DetailRow(
                        label: 'Presupuesto mensual',
                        value: Text(
                          budget != null
                              ? formatCurrency(budget, currency)
                              : 'Sin presupuesto',
                          style: _valueStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CategoryTrendSection(
                category: current,
                currency: currency,
                transactionViewModel: transactionViewModel,
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
