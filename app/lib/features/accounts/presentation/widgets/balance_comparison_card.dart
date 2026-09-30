import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';

double? parseBalanceAmount(String? raw) {
  final text = (raw ?? '').trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

/// Amount input used by the balance wizards: currency prefix, signed decimal
/// filter and a clear button that only shows while there is text.
class BalanceAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;

  const BalanceAmountField({
    super.key,
    required this.controller,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(r'^-?\d*[.,]?\d{0,2}'),
          ),
        ],
        cursorColor: AppColors.authAccent,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.authTextPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.authCardFill,
          hintText: '0,00',
          hintStyle: const TextStyle(color: AppColors.authTextFooter),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 6),
            child: Text(
              currencySymbol,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: AppColors.authTextSecondary,
                  ),
                  tooltip: 'Borrar',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          border: border(AppColors.authAccent.withValues(alpha: 0.6)),
          enabledBorder: border(AppColors.authAccent.withValues(alpha: 0.6)),
          focusedBorder: border(AppColors.authAccent),
        ),
        validator: (value) => parseBalanceAmount(value) == null
            ? 'Ingresa un monto válido'
            : null,
      ),
    );
  }
}

/// Previous-vs-new balance card with the difference box, shared by the
/// update-balance and monthly opening-balance wizards.
class BalanceComparisonCard extends StatelessWidget {
  final String previousLabel;
  final String newLabel;
  final String newBalanceName;
  final double previousBalance;
  final String currency;
  final double? difference;
  final Widget amountField;

  const BalanceComparisonCard({
    super.key,
    this.previousLabel = 'Saldo anterior (en la app)',
    this.newLabel = 'Nuevo saldo actual',
    this.newBalanceName = 'nuevo saldo',
    required this.previousBalance,
    required this.currency,
    required this.difference,
    required this.amountField,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            previousLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.authTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(previousBalance, currency),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 22,
              color: AppColors.authTextSecondary,
            ),
          ),
          Text(
            newLabel,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.authTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          amountField,
          const SizedBox(height: 16),
          _DifferenceBox(
            difference: difference,
            currency: currency,
            newBalanceName: newBalanceName,
          ),
        ],
      ),
    );
  }
}

class _DifferenceBox extends StatelessWidget {
  final double? difference;
  final String currency;
  final String newBalanceName;

  const _DifferenceBox({
    required this.difference,
    required this.currency,
    required this.newBalanceName,
  });

  @override
  Widget build(BuildContext context) {
    final diff = difference;

    final Color tone;
    final IconData icon;
    final String valueText;
    final String message;

    if (diff == null) {
      tone = AppColors.authTextSecondary;
      icon = Icons.remove_rounded;
      valueText = '—';
      message = 'Ingresa el $newBalanceName para calcular la diferencia.';
    } else if (diff == 0) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      valueText = formatCurrency(0, currency);
      message = 'El $newBalanceName coincide con el anterior. '
          'No hay diferencia que justificar.';
    } else if (diff > 0) {
      tone = AppColors.authIncome;
      icon = Icons.arrow_upward_rounded;
      valueText = '+${formatCurrency(diff, currency)}';
      message = 'El $newBalanceName es mayor al anterior. En la siguiente '
          'pantalla podés cargar los movimientos que la justifiquen.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.arrow_downward_rounded;
      valueText = formatCurrency(diff, currency);
      message = 'El $newBalanceName es menor al anterior. En la siguiente '
          'pantalla podés cargar los movimientos que la justifiquen.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone, size: 22),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diferencia',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valueText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: diff == null || diff == 0
                          ? AppColors.authTextPrimary
                          : tone,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.authTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
