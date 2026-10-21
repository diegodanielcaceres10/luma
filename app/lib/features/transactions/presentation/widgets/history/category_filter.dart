import 'package:flutter/material.dart';

import '../../../../../core/widgets/filter_chip_row.dart';
import '../../../data/models/transaction_entry.dart';

/// Category selector of the movements history. "Todas" and "Sin categoría"
/// share the first line; the real categories are listed below. Only one chip
/// is selected across both lines. A null key means all.
class TransactionsCategoryFilter extends StatelessWidget {
  static const double _lineSpacing = 8;

  final List<TransactionCategory> categories;
  final String? selectedKey;
  final ValueChanged<String?> onChanged;

  const TransactionsCategoryFilter({
    super.key,
    required this.categories,
    required this.selectedKey,
    required this.onChanged,
  });

  static String _keyOf(TransactionCategory c) => c.id ?? c.name;

  @override
  Widget build(BuildContext context) {
    final uncategorized = categories.where((c) => c.isUncategorized);
    final named = categories.where((c) => !c.isUncategorized).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterChipRow<String?>(
          options: <({String? value, String label})>[
            (value: null, label: 'Todas'),
            // Same key the screen uses for every category: id, else name.
            for (final c in uncategorized) (value: _keyOf(c), label: c.name),
          ],
          selectedValue: selectedKey,
          onChanged: onChanged,
        ),
        if (named.isNotEmpty) ...[
          const SizedBox(height: _lineSpacing),
          FilterChipRow<String?>(
            options: <({String? value, String label})>[
              for (final c in named) (value: _keyOf(c), label: c.name),
            ],
            selectedValue: selectedKey,
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}
