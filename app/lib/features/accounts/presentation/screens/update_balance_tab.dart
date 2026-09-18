import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Contenido de la nueva pestaña "Actualizar saldo": pantalla aparte del
/// formulario de edición de cuenta, pensada para cargar el saldo real de la
/// cuenta (ej. desde el resumen del banco) y descubrir, a partir de la
/// diferencia con el saldo actual, los movimientos que la explican — en vez
/// de pisar el campo `balance` directamente. Se abre desde el ícono de
/// actualización de cada tarjeta en [AccountsOverviewTab].
///
/// No tiene Scaffold propio — vive dentro del Scaffold del HomeShell, que es
/// quien pone el header (menú + marca Luma + campana) y el
/// bottomNavigationBar.
///
/// Entrega 1: se carga el nuevo monto y se calcula en vivo la diferencia
/// contra el saldo actual. Los pasos siguientes (justificar esa diferencia
/// con movimientos y registrarlos) quedan para una próxima entrega — hoy
/// no se envía nada a la cuenta.
class UpdateBalanceTab extends StatefulWidget {
  /// Cuenta cuyo saldo se va a actualizar. Puede llegar en `null` porque,
  /// igual que en [AccountFormTab], el HomeShell mantiene esta pestaña
  /// siempre montada en el `IndexedStack` aunque todavía no se haya
  /// abierto desde ninguna tarjeta.
  final Account? account;

  /// Se usa solo para leer [AccountViewModel.primaryCurrency] y formatear
  /// los montos; esta entrega todavía no registra nada a través de él.
  final AccountViewModel accountViewModel;

  /// Vuelve a la vista general de "Cuentas", de donde siempre se abre
  /// esta pantalla.
  final VoidCallback onDone;

  const UpdateBalanceTab({
    super.key,
    required this.account,
    required this.accountViewModel,
    required this.onDone,
  });

  @override
  State<UpdateBalanceTab> createState() => _UpdateBalanceTabState();
}

class _UpdateBalanceTabState extends State<UpdateBalanceTab> {
  final _formKey = GlobalKey<FormState>();
  final _newBalanceController = TextEditingController();

  static const _fieldDecoration = InputDecoration(
    filled: true,
    fillColor: AppColors.authCardFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authCardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.authAccent),
    ),
  );

  @override
  void initState() {
    super.initState();
    // Repinta en cada tecla para que la diferencia se recalcule en vivo.
    _newBalanceController.addListener(_onNewBalanceChanged);
  }

  void _onNewBalanceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(UpdateBalanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El HomeShell reutiliza esta misma pantalla para cada cuenta que se
    // abre (cambia solo la `key`), pero por si alguna vez se reusa la
    // instancia con otra cuenta, no queremos arrastrar un monto viejo.
    if (oldWidget.account?.id != widget.account?.id) {
      _newBalanceController.clear();
    }
  }

  @override
  void dispose() {
    _newBalanceController.removeListener(_onNewBalanceChanged);
    _newBalanceController.dispose();
    super.dispose();
  }

  /// La diferencia (nuevo − actual) que después habrá que justificar con
  /// movimientos. `null` mientras el campo esté vacío o no sea un número
  /// válido.
  double? get _difference {
    final currentBalance = widget.account?.balance;
    if (currentBalance == null) return null;

    final newBalance = double.tryParse(_newBalanceController.text.trim());
    if (newBalance == null) return null;

    return newBalance - currentBalance;
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final currency = widget.accountViewModel.primaryCurrency;
    final difference = _difference;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: widget.onDone,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.arrow_back_rounded,
                        color: AppColors.authTextPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Actualizar saldo', style: AppTextStyles.authTitle),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              account == null
                  ? 'Cargá el saldo actual de la cuenta.'
                  : 'Cargá el saldo actual de "${account.name}".',
              style: AppTextStyles.authSubtitle,
            ),
            if (account != null) ...[
              const SizedBox(height: 20),
              const Text('Saldo actual',
                  style: TextStyle(color: AppColors.authTextSecondary)),
              const SizedBox(height: 4),
              Text(
                formatCurrency(account.balance, currency),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Nuevo saldo',
                  style: TextStyle(color: AppColors.authTextSecondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newBalanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration.copyWith(hintText: '0.00'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  return parsed == null ? 'Ingresa un monto válido' : null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Diferencia a justificar',
                  style: TextStyle(color: AppColors.authTextSecondary)),
              const SizedBox(height: 4),
              Text(
                difference == null
                    ? '—'
                    : '${difference >= 0 ? '+' : ''}'
                        '${formatCurrency(difference, currency)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: difference == null
                      ? AppColors.authTextPrimary
                      : difference >= 0
                          ? AppColors.authIncome
                          : AppColors.authExpense,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
