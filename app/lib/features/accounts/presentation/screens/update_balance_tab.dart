import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Mismos íconos genéricos que usa [AccountsOverviewTab] para diferenciar
/// las tarjetas: las cuentas no guardan ícono ni color propio en la base,
/// así que se asigna uno por posición en la lista. Se repite acá para que el
/// header de esta pantalla coincida con la tarjeta desde la que se abrió.
/// Si cambia allá, hay que cambiarlo también acá (o extraerlo a un lugar
/// común).
const _kAccountIcons = [
  Icons.account_balance_wallet_rounded,
  Icons.credit_card_rounded,
  Icons.savings_rounded,
  Icons.account_balance_rounded,
];

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
/// Entrega 4: agrega el popup de "Agregar movimiento" que abre el botón de
/// la Entrega 3 — por ahora solo título, "Cancelar" y "Guardar", todavía
/// sin campos ni guardado real. La lista de movimientos, los totales y el
/// botón "Guardar y actualizar saldo" quedan para una próxima entrega — hoy
/// no se envía nada a la cuenta.
class UpdateBalanceTab extends StatefulWidget {
  /// Cuenta cuyo saldo se va a actualizar. Puede llegar en `null` porque,
  /// igual que en [AccountFormTab], el HomeShell mantiene esta pestaña
  /// siempre montada en el `IndexedStack` aunque todavía no se haya
  /// abierto desde ninguna tarjeta.
  final Account? account;

  /// Se usa para leer [AccountViewModel.primaryCurrency] (formato de los
  /// montos) y la posición de la cuenta en la lista (ícono y color del
  /// header); esta entrega todavía no registra nada a través de él.
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

  /// Convierte lo escrito en el campo a número. Acepta coma o punto como
  /// separador decimal (el teclado numérico en español suele ofrecer coma).
  /// `null` si está vacío o no es un número válido.
  double? _parseAmount(String? raw) {
    final text = (raw ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// La diferencia (nuevo − anterior) que después habrá que justificar con
  /// movimientos. `null` mientras el campo esté vacío o no sea un número
  /// válido. Se redondea a centavos para que la resta de dobles no deje
  /// restos tipo 499,99999… ni impida detectar el caso "sin diferencia".
  double? get _difference {
    final currentBalance = widget.account?.balance;
    if (currentBalance == null) return null;

    final newBalance = _parseAmount(_newBalanceController.text);
    if (newBalance == null) return null;

    final cents = ((newBalance - currentBalance) * 100).round();
    return cents / 100;
  }

  /// Posición de la cuenta en la lista, para reutilizar el mismo ícono y
  /// color que tiene su tarjeta en la vista general.
  int _accountIndex(Account account) {
    final index = widget.accountViewModel.accounts.indexOf(account);
    return index < 0 ? 0 : index;
  }

  /// Popup que abre el botón "Agregar movimiento". Por ahora solo título,
  /// "Cancelar" y "Guardar" — sin campos ni guardado real; ambos botones
  /// se limitan a cerrar el popup. Mismo estilo que los diálogos de
  /// [InvoicesTab] (fondo, borde y colores de los botones).
  Future<void> _showAddMovementDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        title: const Text(
          'Agregar movimiento',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.authTextSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.authAccent,
              foregroundColor: AppColors.authBackgroundBottom,
            ),
            // Todavía no guarda nada: solo cierra el popup.
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _amountDecoration(String currencySymbol) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.authCardFill,
      hintText: '0,00',
      hintStyle: const TextStyle(color: AppColors.authTextFooter),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      // prefixIcon (y no prefixText) para que el símbolo se vea siempre,
      // incluso con el campo vacío y sin foco.
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
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      // Botón para vaciar el campo, solo cuando hay algo escrito.
      suffixIcon: _newBalanceController.text.isEmpty
          ? null
          : IconButton(
              onPressed: _newBalanceController.clear,
              icon: const Icon(
                Icons.cancel_rounded,
                size: 18,
                color: AppColors.authTextSecondary,
              ),
              tooltip: 'Borrar',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      border: border(AppColors.authAccent.withValues(alpha: 0.6)),
      enabledBorder: border(AppColors.authAccent.withValues(alpha: 0.6)),
      focusedBorder: border(AppColors.authAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final currency = widget.accountViewModel.primaryCurrency;
    final currencySymbol =
        NumberFormat.currency(locale: 'es_ES', name: currency).currencySymbol;

    return SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: widget.onDone,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppColors.authTextPrimary),
                ),
              ),
            ),
            if (account != null) ...[
              const SizedBox(height: 8),
              _AccountHeader(
                account: account,
                color: colorFromHex(
                  kCategoryColors[
                      _accountIndex(account) % kCategoryColors.length],
                ),
                icon: _kAccountIcons[
                    _accountIndex(account) % _kAccountIcons.length],
              ),
            ],
            const SizedBox(height: 20),
            const Text('Actualizar saldo', style: AppTextStyles.authTitle),
            const SizedBox(height: 8),
            const Text(
              'Ingresa el nuevo saldo de tu cuenta y agrega los movimientos '
              'que justifiquen la diferencia.',
              style: AppTextStyles.authSubtitle,
            ),
            if (account != null) ...[
              const SizedBox(height: 24),
              _BalanceCard(
                previousBalance: account.balance,
                currency: currency,
                difference: _difference,
                amountField: TextFormField(
                  controller: _newBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  // Hasta 2 decimales, coma o punto, y un "-" opcional al
                  // inicio (una cuenta puede estar en descubierto).
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
                  decoration: _amountDecoration(currencySymbol),
                  validator: (value) => _parseAmount(value) == null
                      ? 'Ingresa un monto válido'
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              _MovementsSectionHeader(
                onAddMovement: () => _showAddMovementDialog(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Header de la cuenta que se está actualizando: ícono, nombre y estado.
/// El prototipo muestra además el tipo de cuenta ("Cuenta corriente"), pero
/// hoy `accounts` no guarda ese dato, así que se muestra si está activa o
/// inactiva, igual que la tarjeta de la vista general.
class _AccountHeader extends StatelessWidget {
  final Account account;
  final Color color;
  final IconData icon;

  const _AccountHeader({
    required this.account,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.authTextPrimary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                account.isActive ? 'Cuenta activa' : 'Cuenta inactiva',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.authTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Título de la sección "Movimientos para justificar la diferencia" y el
/// botón "Agregar movimiento" del prototipo, en la misma fila.
///
/// [onAddMovement] abre el popup de alta de movimiento (Entrega 4); el
/// popup en sí todavía no tiene campos ni guarda nada.
class _MovementsSectionHeader extends StatelessWidget {
  final VoidCallback onAddMovement;

  const _MovementsSectionHeader({required this.onAddMovement});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            'Movimientos para justificar la diferencia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onAddMovement,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.authAccent,
            side: const BorderSide(color: AppColors.authAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Agregar movimiento',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta principal del prototipo: saldo anterior → nuevo saldo (campo
/// recibido por parámetro, porque el controller vive en el State) y, debajo,
/// la caja con la diferencia.
class _BalanceCard extends StatelessWidget {
  final double previousBalance;
  final String currency;
  final double? difference;
  final Widget amountField;

  const _BalanceCard({
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
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo anterior (en la app)',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatCurrency(previousBalance, currency),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 22,
                  color: AppColors.authTextSecondary,
                ),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuevo saldo actual',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    amountField,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DifferenceBox(difference: difference, currency: currency),
        ],
      ),
    );
  }
}

/// Caja "Diferencia": monto con signo y color según sea menor, mayor o igual
/// al saldo anterior, más un mensaje que explica qué sigue.
class _DifferenceBox extends StatelessWidget {
  /// `null` mientras el nuevo saldo esté vacío o no sea válido.
  final double? difference;
  final String currency;

  const _DifferenceBox({required this.difference, required this.currency});

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
      message = 'Ingresa el nuevo saldo para calcular la diferencia.';
    } else if (diff == 0) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      valueText = formatCurrency(0, currency);
      message = 'El nuevo saldo coincide con el anterior. '
          'No hay diferencia que justificar.';
    } else if (diff > 0) {
      tone = AppColors.authIncome;
      icon = Icons.arrow_upward_rounded;
      valueText = '+${formatCurrency(diff, currency)}';
      message = 'El nuevo saldo es mayor al anterior. '
          'Agrega los movimientos que justifiquen la diferencia.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.arrow_downward_rounded;
      valueText = formatCurrency(diff, currency);
      message = 'El nuevo saldo es menor al anterior. '
          'Agrega los movimientos que justifiquen la diferencia.';
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
          // Ancho máximo acotado: si el monto es muy grande se achica (en
          // vez de desbordar) y el mensaje conserva su espacio a la derecha.
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
