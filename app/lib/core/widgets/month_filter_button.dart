import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';

/// 'septiembre 2025' -> 'Septiembre 2025'.
String formatMonthLabel(DateTime date) {
  final formatted = DateFormat('MMMM yyyy', 'es').format(date);
  return formatted[0].toUpperCase() + formatted.substring(1);
}

/// Filtro por mes compartido por las pantallas: un botón tipo pill que
/// muestra el mes elegido ("Septiembre 2026") y, al tocarlo, abre una hoja
/// inferior con los últimos 12 meses.
///
/// Siempre es un mes puntual — no hay opción de "todos los meses". No guarda
/// estado: cada pantalla decide dónde vive el mes elegido (en la URL, en un
/// ViewModel, etc.) y qué hacer cuando cambia ([onChanged]); con qué mes
/// arranca también lo decide la pantalla (hoy, el mes en curso).
///
/// Pensado para el slot `action` de `ScreenHeader`:
/// ```dart
/// ScreenHeader(
///   title: 'Movimientos',
///   action: MonthFilterButton(
///     selectedMonth: month,
///     onChanged: (picked) => ...,
///   ),
/// )
/// ```
class MonthFilterButton extends StatelessWidget {
  final DateTime selectedMonth;

  /// Se llama con el mes elegido (el 1º de ese mes). No se llama si se cierra
  /// la hoja sin tocar nada.
  final ValueChanged<DateTime> onChanged;

  const MonthFilterButton({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: AppColors.authBackgroundBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MonthPickerSheet(selectedMonth: selectedMonth),
    );

    if (picked != null && context.mounted) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.authCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.authCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: AppColors.authTextPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              formatMonthLabel(selectedMonth),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.authTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja inferior para elegir uno de los últimos 12 meses.
class _MonthPickerSheet extends StatelessWidget {
  final DateTime selectedMonth;

  const _MonthPickerSheet({required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final months = List.generate(
      12,
      (i) => DateTime(currentMonth.year, currentMonth.month - i),
    );

    return SafeArea(
      top: false,
      // Acota el alto total de la hoja (handle + título + lista) a una
      // fracción de la pantalla para que no desborde en pantallas bajas.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.authCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Elegí un mes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: months.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.authCardBorder,
                  ),
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isSelected = month.year == selectedMonth.year &&
                        month.month == selectedMonth.month;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        formatMonthLabel(month),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.authAccent
                              : AppColors.authTextPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.authAccent,
                              size: 20,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(month),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
