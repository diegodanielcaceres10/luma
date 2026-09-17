import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';

/// Contenido de la pestaña "Transferencia entre cuentas". No tiene
/// Scaffold propio — vive dentro del Scaffold del HomeShell, que es quien
/// pone el header y el bottomNavigationBar.
///
/// Por ahora solo permite elegir la cuenta de origen y la de destino.
/// El monto, la fecha y el guardado real se agregan en una entrega
/// posterior — el botón de abajo queda deshabilitado a propósito.
class TransferFormTab extends StatefulWidget {
  final AccountViewModel accountViewModel;

  /// Se llama al volver atrás (todavía no hay nada para guardar).
  final VoidCallback onDone;

  const TransferFormTab({
    super.key,
    required this.accountViewModel,
    required this.onDone,
  });

  @override
  State<TransferFormTab> createState() => _TransferFormTabState();
}

class _TransferFormTabState extends State<TransferFormTab> {
  String? _originAccountId;
  String? _destinationAccountId;

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
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: widget.accountViewModel,
        builder: (context, _) {
          final accounts = widget.accountViewModel.activeAccounts;

          // Cada select excluye la cuenta ya elegida en el otro — así no
          // se puede transferir una cuenta a sí misma. Si la cuenta
          // elegida en un select deja de estar disponible en el otro
          // (porque la acaban de elegir ahí), se limpia para no dejar un
          // valor que ya no está entre las opciones.
          final originOptions = accounts
              .where((Account a) => a.id != _destinationAccountId)
              .toList();
          final destinationOptions = accounts
              .where((Account a) => a.id != _originAccountId)
              .toList();

          return ListView(
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
                  const Text(
                    'Transferencia entre cuentas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (accounts.length < 2)
                const Text(
                  'Necesitás al menos dos cuentas activas para transferir '
                  'entre ellas.',
                  style: TextStyle(color: AppColors.authExpense),
                )
              else ...[
                const Text('Cuenta de origen',
                    style: TextStyle(color: AppColors.authTextSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _originAccountId,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  hint: const Text(
                    'Seleccioná la cuenta de origen',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  decoration: _fieldDecoration,
                  items: originOptions
                      .map(
                        (Account a) => DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text(a.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _originAccountId = value;
                    if (value != null && value == _destinationAccountId) {
                      _destinationAccountId = null;
                    }
                  }),
                ),
                const SizedBox(height: 20),
                const Text('Cuenta de destino',
                    style: TextStyle(color: AppColors.authTextSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _destinationAccountId,
                  dropdownColor: AppColors.authBackgroundBottom,
                  style: const TextStyle(color: AppColors.authTextPrimary),
                  hint: const Text(
                    'Seleccioná la cuenta de destino',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                  decoration: _fieldDecoration,
                  items: destinationOptions
                      .map(
                        (Account a) => DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text(a.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _destinationAccountId = value;
                    if (value != null && value == _originAccountId) {
                      _originAccountId = null;
                    }
                  }),
                ),
                const SizedBox(height: 32),
                // El monto, la fecha y el guardado real quedan para una
                // entrega posterior — el botón se deja deshabilitado a
                // propósito para no sugerir una función que todavía no
                // hace nada.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.authAccent,
                      foregroundColor: AppColors.authBackgroundBottom,
                      disabledBackgroundColor:
                          AppColors.authAccent.withValues(alpha: 0.3),
                      disabledForegroundColor: AppColors.authBackgroundBottom
                          .withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: null,
                    child: const Text('Transferir (próximamente)'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
