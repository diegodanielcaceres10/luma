import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Single-select pill filters that wrap onto new lines. [T] is the option
/// value type; `null` in a `String?` filter means "all". No color dot: colors
/// stay where the data itself is listed.
class FilterChipRow<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.value == selectedValue;
        return GestureDetector(
          onTap: () => onChanged(option.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.authAccent.withValues(alpha: 0.18)
                  : AppColors.authCardFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    isSelected ? AppColors.authAccent : AppColors.authCardBorder,
              ),
            ),
            child: Text(
              option.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.authTextPrimary
                    : AppColors.authTextSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
