import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Fila de filtros de una sola selección, en pastilla: chips que fluyen
/// horizontalmente y saltan de línea al llegar al borde (Wrap). Mismo
/// look en toda la app — Facturas (estado) y Movimientos (tipo, período,
/// cuenta, categoría).
///
/// [T] es el tipo del valor de cada opción — un enum de filtro, o
/// `String?` cuando el filtro es dinámico (cuenta/categoría) y `null`
/// representa "todas". No lleva punto de color: si el filtro es sobre
/// algo con color propio (una categoría, una cuenta), ese color no se
/// repite acá — queda para donde se lista el dato en sí.
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
