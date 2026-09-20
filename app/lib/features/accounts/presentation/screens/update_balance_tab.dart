import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
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
///
/// Entrega 5: el popup ahora tiene los campos para cargar un movimiento
/// (Monto, Categoría, Descripción y Fecha). Al tocar "Guardar" se valida y
/// se agrega a [_UpdateBalanceTabState._pendingMovements], solo en memoria
/// — todavía no hay lista visible ni se persiste nada en la base.
///
/// Entrega 6: agrega el listado de movimientos cargados (bajo "Agregar
/// movimiento"), con la fila categoría/descripción/fecha, el monto con
/// signo y un botón para quitarlo — todo sobre [_pendingMovements], en
/// memoria. El total y el botón "Guardar y actualizar saldo" del
/// prototipo quedan para una próxima entrega.
///
/// Entrega 7: agrega el footer final — [_MovementsSummaryCard] con el
/// total de movimientos y el estado de la diferencia, y el botón
/// "Guardar y actualizar saldo". Que el total no cubra toda la diferencia
/// ya no bloquea el botón: esa parte se guardará como un ingreso o gasto
/// sin categoría (mensaje que muestra la propia tarjeta). El botón
/// todavía no persiste nada — ver [_UpdateBalanceTabState._saveAndUpdateBalance].
///
/// Entrega 8: el botón "Guardar y actualizar saldo" ya persiste de
/// verdad. Cada movimiento de [_UpdateBalanceTabState._pendingMovements]
/// se inserta como una transacción real (`create_transaction`, el mismo
/// RPC que usa [AddTransactionTab]), con `type`/`amount` derivados del
/// signo que ya tenía el movimiento; si queda una parte de la diferencia
/// sin cubrir, se agrega una transacción más sin categoría (ingreso o
/// gasto no declarado). El propio RPC actualiza `accounts.balance` en la
/// misma operación — acá no se hace ningún update aparte sobre la cuenta.
class UpdateBalanceTab extends StatefulWidget {
  /// Cuenta cuyo saldo se va a actualizar. Puede llegar en `null` porque,
  /// igual que en [AccountFormTab], el HomeShell mantiene esta pestaña
  /// siempre montada en el `IndexedStack` aunque todavía no se haya
  /// abierto desde ninguna tarjeta.
  final Account? account;

  /// Se usa para leer [AccountViewModel.primaryCurrency] (formato de los
  /// montos), la posición de la cuenta en la lista (ícono y color del
  /// header) y, tras guardar, recargar la lista para que el nuevo saldo
  /// (ya actualizado por el RPC) se vea en pantalla.
  final AccountViewModel accountViewModel;

  /// Categorías disponibles para el selector del popup "Agregar
  /// movimiento" (tanto de ingreso como de gasto: el movimiento puede ir
  /// en cualquier sentido según la diferencia a justificar).
  final CategoryViewModel categoryViewModel;

  /// Crea cada movimiento (y el ajuste no declarado, si hace falta) como
  /// una transacción real al presionar "Guardar y actualizar saldo".
  final TransactionViewModel transactionViewModel;

  /// Igual que en [AddTransactionTab]: puede venir `null` si todavía no
  /// cargó la sesión; en ese caso se manda como cadena vacía al crear las
  /// transacciones (la policy de RLS de todos modos las rechazaría).
  final String? userId;

  /// Vuelve a la vista general de "Cuentas", de donde siempre se abre
  /// esta pantalla.
  final VoidCallback onDone;

  const UpdateBalanceTab({
    super.key,
    required this.account,
    required this.accountViewModel,
    required this.categoryViewModel,
    required this.transactionViewModel,
    required this.userId,
    required this.onDone,
  });

  @override
  State<UpdateBalanceTab> createState() => _UpdateBalanceTabState();
}

class _UpdateBalanceTabState extends State<UpdateBalanceTab> {
  final _formKey = GlobalKey<FormState>();
  final _newBalanceController = TextEditingController();

  /// Movimientos cargados desde el popup, solo en memoria. Entrega 5: se
  /// guardan acá para una próxima entrega que los muestre en una lista y
  /// los use para actualizar el saldo; por ahora no se renderizan ni se
  /// envían a la base.
  final List<PendingMovement> _pendingMovements = [];

  /// true mientras [_saveAndUpdateBalance] está insertando transacciones.
  /// Deshabilita el botón (con spinner), "Agregar movimiento" y el tacho
  /// de cada fila, para no dejar mutar la lista a mitad de un guardado.
  bool _isSaving = false;

  void _addPendingMovement(PendingMovement movement) {
    setState(() => _pendingMovements.add(movement));
  }

  /// Saca un movimiento de la lista en memoria (botón de tacho en cada
  /// fila). Entrega 6: solo quita el ítem de [_pendingMovements] — no hay
  /// nada que deshacer en la base porque todavía no se persiste nada.
  void _removePendingMovement(PendingMovement movement) {
    setState(() => _pendingMovements.remove(movement));
  }

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

  /// Suma de los movimientos cargados (ya con signo — ver [PendingMovement]).
  /// Redondeada a centavos, mismo motivo que en [_difference].
  double get _pendingMovementsTotal {
    final cents = _pendingMovements.fold<int>(
      0,
      (sum, movement) => sum + (movement.amount * 100).round(),
    );
    return cents / 100;
  }

  /// Parte de la diferencia que los movimientos cargados no cubren.
  /// `null` mientras no haya una diferencia calculable (ver [_difference]).
  /// Positivo: falta un ingreso; negativo: falta un gasto; cero (o muy
  /// cerca, por redondeo de centavos): los movimientos ya la justifican
  /// por completo.
  double? get _unjustifiedRemainder {
    final diff = _difference;
    if (diff == null) return null;

    final cents = ((diff - _pendingMovementsTotal) * 100).round();
    return cents / 100;
  }

  /// Posición de la cuenta en la lista, para reutilizar el mismo ícono y
  /// color que tiene su tarjeta en la vista general.
  int _accountIndex(Account account) {
    final index = widget.accountViewModel.accounts.indexOf(account);
    return index < 0 ? 0 : index;
  }

  /// Acción del botón "Guardar y actualizar saldo". Entrega 8: inserta
  /// cada movimiento de [_pendingMovements] como una transacción real
  /// (`create_transaction`) y, si queda una parte de la diferencia sin
  /// cubrir, una transacción más sin categoría para esa parte. El RPC ya
  /// actualiza `accounts.balance` con cada insert — acá no se hace ningún
  /// update aparte sobre la cuenta.
  ///
  /// Se insertan de a una, en orden, para poder distinguir cuáles quedan
  /// guardadas si una falla a mitad de camino: esas se sacan de
  /// [_pendingMovements] antes de mostrar el error, para no duplicarlas
  /// si el usuario reintenta.
  Future<void> _saveAndUpdateBalance() async {
    final account = widget.account;
    final remainder = _unjustifiedRemainder;
    if (account == null || remainder == null || _isSaving) return;

    setState(() => _isSaving = true);

    final userId = widget.userId ?? '';
    final saved = <PendingMovement>[];

    try {
      for (final movement in _pendingMovements) {
        final success = await widget.transactionViewModel.createTransaction(
          userId: userId,
          accountId: account.id,
          categoryId: movement.category.id,
          type: movement.category.type,
          amount: movement.amount.abs(),
          description: movement.description,
          date: movement.date,
        );
        if (!success) {
          throw Exception(
            widget.transactionViewModel.errorMessage ??
                'No se pudo guardar un movimiento.',
          );
        }
        saved.add(movement);
      }

      if (remainder.abs() >= _kRemainderEpsilon) {
        final success = await widget.transactionViewModel.createTransaction(
          userId: userId,
          accountId: account.id,
          categoryId: null,
          type: remainder > 0 ? 'income' : 'expense',
          amount: remainder.abs(),
          description: 'Ajuste no declarado al actualizar el saldo',
          date: DateTime.now(),
        );
        if (!success) {
          throw Exception(
            widget.transactionViewModel.errorMessage ??
                'No se pudo guardar el ajuste no declarado.',
          );
        }
      }

      // El saldo ya quedó actualizado en la base (cada create_transaction
      // lo hizo); recargamos la lista de cuentas para que se vea acá.
      await widget.accountViewModel.loadAccounts();
      if (!mounted) return;

      setState(() {
        _pendingMovements.clear();
        _newBalanceController.clear();
      });
      widget.onDone();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pendingMovements.removeWhere(saved.contains);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Popup que abre el botón "Agregar movimiento". Entrega 5: ya tiene los
  /// campos (Monto, Categoría, Descripción y Fecha) delegados a
  /// [_AddMovementDialog]; al guardar, el movimiento se agrega a
  /// [_pendingMovements] y el popup se cierra solo. Todavía no hay lista
  /// visible ni se persiste nada en la base.
  Future<void> _showAddMovementDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddMovementDialog(
        categoryViewModel: widget.categoryViewModel,
        onSave: _addPendingMovement,
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
        child: Column(
          children: [
            // Barra de progreso fina arriba mientras se guardan las
            // transacciones — mismo criterio que usa AddTransactionTab.
            if (_isSaving)
              const LinearProgressIndicator(
                backgroundColor: AppColors.authCardBorder,
                color: AppColors.authAccent,
                minHeight: 3,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: _isSaving ? null : widget.onDone,
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
                  const Text('Actualizar saldo',
                      style: AppTextStyles.authTitle),
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
                      enabled: !_isSaving,
                    ),
                    if (_pendingMovements.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _MovementsList(
                        movements: _pendingMovements,
                        currency: currency,
                        onDelete: _removePendingMovement,
                        enabled: !_isSaving,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _MovementsSummaryCard(
                      total: _pendingMovementsTotal,
                      remainder: _unjustifiedRemainder,
                      currency: currency,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.authAccent,
                          foregroundColor: AppColors.authBackgroundBottom,
                          disabledBackgroundColor:
                              AppColors.authAccent.withValues(alpha: 0.4),
                          disabledForegroundColor: AppColors
                              .authBackgroundBottom
                              .withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        // Habilitado en cuanto hay un saldo nuevo válido — que
                        // los movimientos no cubran toda la diferencia ya NO lo
                        // bloquea (ver [_MovementsSummaryCard]): lo que falte se
                        // guarda como ingreso/gasto no declarado, sin categoría.
                        onPressed: _difference == null || _isSaving
                            ? null
                            : _saveAndUpdateBalance,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.authBackgroundBottom,
                                ),
                              )
                            : const Text(
                                'Guardar y actualizar saldo',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  /// false mientras se está guardando ([_UpdateBalanceTabState._isSaving]):
  /// deshabilita el botón para no agregar movimientos a mitad de un
  /// guardado.
  final bool enabled;

  const _MovementsSectionHeader({
    required this.onAddMovement,
    this.enabled = true,
  });

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
          onPressed: enabled ? onAddMovement : null,
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

/// Abreviaturas de mes en español (3 letras, sin punto), para mostrar la
/// fecha de cada movimiento igual que en el prototipo ("12 sep 2025").
/// [DateFormat] de `intl` agrega un punto ("sept.") con el locale 'es', así
/// que se arma a mano en vez de depender de eso.
const _kMonthAbbreviations = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String _formatMovementDate(DateTime date) {
  final month = _kMonthAbbreviations[date.month - 1];
  return '${date.day} $month ${date.year}';
}

/// Umbral bajo el cual una diferencia se considera "cero" — evita falsos
/// "no coincide"/"falta guardar un ajuste" por restos de redondeo de
/// centavos. Se comparte entre [_MovementsSummaryCard] (qué mensaje
/// mostrar) y [_UpdateBalanceTabState._saveAndUpdateBalance] (si hace
/// falta crear la transacción de ajuste no declarado).
const _kRemainderEpsilon = 0.005;

/// Lista de movimientos ya cargados desde el popup "Agregar movimiento",
/// dentro de una sola tarjeta con separadores entre filas — igual que en
/// el prototipo. Entrega 6: solo el listado; el total y el botón "Guardar
/// y actualizar saldo" del prototipo quedan para una próxima entrega.
class _MovementsList extends StatelessWidget {
  final List<PendingMovement> movements;
  final String currency;
  final void Function(PendingMovement movement) onDelete;

  /// false mientras se está guardando ([_UpdateBalanceTabState._isSaving]):
  /// deshabilita el tacho de cada fila para no mutar la lista a mitad de
  /// un guardado.
  final bool enabled;

  const _MovementsList({
    required this.movements,
    required this.currency,
    required this.onDelete,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            _MovementListTile(
              movement: movements[i],
              currency: currency,
              onDelete: enabled ? () => onDelete(movements[i]) : null,
            ),
            if (i < movements.length - 1)
              const Divider(color: AppColors.authCardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

/// Una fila de [_MovementsList]: círculo con el color/ícono de la
/// categoría, categoría + descripción + fecha, monto con signo (mismo
/// criterio de color que [_DifferenceBox]: verde si suma, rojo si resta) y
/// el botón para sacarlo de la lista.
class _MovementListTile extends StatelessWidget {
  final PendingMovement movement;
  final String currency;

  /// `null` deshabilita el botón de tacho (mientras se está guardando).
  final VoidCallback? onDelete;

  const _MovementListTile({
    required this.movement,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final amount = movement.amount;
    final amountText = amount > 0
        ? '+${formatCurrency(amount, currency)}'
        : formatCurrency(amount, currency);
    final amountColor =
        amount > 0 ? AppColors.authIncome : AppColors.authExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
                if (movement.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    movement.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.authTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  _formatMovementDate(movement.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.authTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.authTextSecondary,
            ),
            tooltip: 'Quitar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Footer con el total de los movimientos cargados y el estado de la
/// diferencia, en el mismo estilo de dos columnas separadas por una línea
/// que usa [_DifferenceBox]. Que [remainder] no sea cero (o casi, por
/// redondeo) ya no bloquea el botón "Guardar y actualizar saldo" — solo
/// cambia el mensaje, para avisar que esa parte se va a guardar como un
/// ingreso o gasto sin categoría.
class _MovementsSummaryCard extends StatelessWidget {
  final double total;

  /// Parte de la diferencia sin cubrir por los movimientos. `null`
  /// mientras no haya un saldo nuevo válido (ver
  /// [_UpdateBalanceTabState._unjustifiedRemainder]).
  final double? remainder;
  final String currency;

  const _MovementsSummaryCard({
    required this.total,
    required this.remainder,
    required this.currency,
  });

  /// Umbral bajo el cual se considera "sin diferencia" — evita falsos
  /// "no coincide" por restos de redondeo de centavos.
  static const _epsilon = _kRemainderEpsilon;

  @override
  Widget build(BuildContext context) {
    final rem = remainder;

    final Color tone;
    final IconData icon;
    final String title;
    final String message;

    if (rem == null) {
      tone = AppColors.authTextSecondary;
      icon = Icons.info_outline_rounded;
      title = 'Falta el saldo nuevo';
      message = 'Ingresa el nuevo saldo para calcular la diferencia.';
    } else if (rem.abs() < _epsilon) {
      tone = AppColors.authAccent;
      icon = Icons.check_rounded;
      title = 'Coincide con la diferencia';
      message = 'El saldo se actualiza correctamente.';
    } else if (rem > 0) {
      tone = AppColors.authIncome;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se guardará como ingreso no declarado, sin categoría, '
          'por ${formatCurrency(rem, currency)}.';
    } else {
      tone = AppColors.authExpense;
      icon = Icons.priority_high_rounded;
      title = 'Diferencia sin justificar';
      message = 'Se guardará como gasto no declarado, sin categoría, '
          'por ${formatCurrency(rem.abs(), currency)}.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.authAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    color: AppColors.authAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total de movimientos',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatCurrency(total, currency),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.authCardBorder,
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tone, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tone,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: AppColors.authTextSecondary,
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
    );
  }
}

/// Movimiento cargado desde el popup "Agregar movimiento" mientras se
/// termina de justificar la diferencia de saldo. [amount] ya viene con
/// signo (negativo si [category] es de gasto, positivo si es de ingreso)
/// — ver [_AddMovementDialogState._save]. Vive solo en memoria (ver
/// [_UpdateBalanceTabState._pendingMovements]) — todavía no se persiste en
/// la base.
class PendingMovement {
  final double amount;
  final Category category;
  final String? description;
  final DateTime date;

  const PendingMovement({
    required this.amount,
    required this.category,
    required this.date,
    this.description,
  });
}

/// Contenido del popup "Agregar movimiento": Monto, Categoría, Descripción
/// (opcional) y Fecha. Es un `StatefulWidget` propio (en vez de vivir en
/// [_UpdateBalanceTabState]) porque necesita su propio `Form` y controllers
/// que se descartan al cerrar el popup, sin interferir con el formulario
/// del saldo nuevo que queda atrás.
///
/// El campo "Monto" solo pide la magnitud (siempre positiva): el signo
/// final lo decide el tipo de la categoría elegida (gasto resta, ingreso
/// suma — ver [_AddMovementDialogState._save]), así que no filtra las
/// categorías por tipo: se listan todas mezcladas, diferenciadas por
/// ícono y color.
class _AddMovementDialog extends StatefulWidget {
  final CategoryViewModel categoryViewModel;
  final void Function(PendingMovement movement) onSave;

  const _AddMovementDialog({
    required this.categoryViewModel,
    required this.onSave,
  });

  @override
  State<_AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<_AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  static const _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.authTextSecondary,
  );

  static const _fieldDecoration = InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.authCardFill,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    hintStyle: TextStyle(color: AppColors.authTextFooter),
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
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Mismo rango de fechas que usa [AddTransactionTab]: hasta hoy, sin
  /// límite hacia atrás salvo el año 2020 (arranque razonable para no
  /// scrollear de más en el picker).
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.authAccent,
            onPrimary: AppColors.authBackgroundBottom,
            surface: AppColors.authBackgroundBottom,
            onSurface: AppColors.authTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return;

    final rawAmount = double.parse(_amountController.text.replaceAll(',', '.'));
    // El signo lo pone la categoría, no el usuario: si es de gasto resta
    // del saldo, si es de ingreso suma. El campo "Monto" solo pide la
    // magnitud (siempre positiva).
    final signedAmount =
        _selectedCategory!.type == 'expense' ? -rawAmount : rawAmount;

    widget.onSave(
      PendingMovement(
        amount: signedAmount,
        category: _selectedCategory!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categoryViewModel.categories;

    return AlertDialog(
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
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monto', style: _labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // Solo magnitud, sin "-": el signo final lo pone el tipo
                // de la categoría elegida (ver [_save]).
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration.copyWith(hintText: '0,00'),
                validator: (value) {
                  final text = (value ?? '').trim().replaceAll(',', '.');
                  if (text.isEmpty) return 'Ingresa un monto';
                  final parsed = double.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Categoría', style: _labelStyle),
              const SizedBox(height: 6),
              if (widget.categoryViewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
                  ),
                )
              else if (categories.isEmpty)
                const Text(
                  'No hay categorías todavía.',
                  style: TextStyle(
                    color: AppColors.authExpense,
                    fontSize: 13,
                  ),
                )
              else
                DropdownButtonFormField<Category>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  decoration: _fieldDecoration,
                  hint: const Text(
                    'Seleccioná una categoría',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) =>
                      value == null ? 'Seleccioná una categoría' : null,
                ),
              const SizedBox(height: 16),
              const Text('Descripción (opcional)', style: _labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppColors.authTextPrimary),
                decoration: _fieldDecoration.copyWith(
                  hintText: 'Ej: Retiro en efectivo',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Fecha', style: _labelStyle),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: _fieldDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/'
                        '${_selectedDate.month.toString().padLeft(2, '0')}/'
                        '${_selectedDate.year}',
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.authTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
          onPressed: categories.isEmpty ? null : _save,
          child: const Text('Guardar'),
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
