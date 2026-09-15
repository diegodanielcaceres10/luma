import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../data/models/category.dart';
import '../view_models/category_view_model.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final String userId;
  final CategoryViewModel categoryViewModel;

  const CategoriesScreen({
    super.key,
    required this.userId,
    required this.categoryViewModel,
  });

  Future<void> _openForm(
    BuildContext context, {
    Category? category,
    String initialType = 'expense',
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryFormScreen(
          userId: userId,
          categoryViewModel: categoryViewModel,
          category: category,
          initialType: initialType,
        ),
      ),
    );
  }

  Future<void> _pickTypeAndCreate(BuildContext context) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_rounded,
                  color: AppColors.authExpense),
              title: const Text('Categoría de gasto',
                  style: TextStyle(color: AppColors.authTextPrimary)),
              onTap: () => Navigator.of(context).pop('expense'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.add_rounded, color: AppColors.authIncome),
              title: const Text('Categoría de ingreso',
                  style: TextStyle(color: AppColors.authTextPrimary)),
              onTap: () => Navigator.of(context).pop('income'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (type != null) {
      await _openForm(context, initialType: type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
      appBar: AppBar(
        backgroundColor: AppColors.authBackgroundBottom,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.authTextPrimary),
        title: const Text(
          'Categorías',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickTypeAndCreate(context),
        backgroundColor: AppColors.authAccent,
        foregroundColor: AppColors.authBackgroundBottom,
        child: const Icon(Icons.add_rounded),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.authBackgroundTop,
              AppColors.authBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
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

              if (expenses.isEmpty && incomes.isEmpty) {
                return const Center(
                  child: Text(
                    'Todavía no hay categorías.\nTocá + para crear la primera.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSubtitle,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                children: [
                  if (expenses.isNotEmpty) ...[
                    const _SectionLabel('Gastos'),
                    _CategoryGroup(
                      categories: expenses,
                      onTap: (c) => _openForm(context, category: c),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (incomes.isNotEmpty) ...[
                    const _SectionLabel('Ingresos'),
                    _CategoryGroup(
                      categories: incomes,
                      onTap: (c) => _openForm(context, category: c),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
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
