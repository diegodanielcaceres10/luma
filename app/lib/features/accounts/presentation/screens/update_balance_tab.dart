import 'package:flutter/material.dart';

import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/account.dart';

/// Contenido de la nueva pestaña "Actualizar saldo": pantalla aparte del
/// formulario de edición de cuenta, pensada solo para cargar rápido el
/// saldo actual desde el ícono de actualización de cada tarjeta en
/// [AccountsOverviewTab]. Todavía no hay un prototipo para esta pantalla.
///
/// No tiene Scaffold propio — vive dentro del Scaffold del HomeShell, que es
/// quien pone el header (menú + marca Luma + campana) y el
/// bottomNavigationBar.
///
/// Por ahora solo está desarrollado el header propio de la pantalla (título
/// y bajada con el nombre de la cuenta); el formulario para actualizar el
/// saldo queda para una próxima entrega.
class UpdateBalanceTab extends StatelessWidget {
  /// Cuenta cuyo saldo se va a actualizar. Puede llegar en `null` porque,
  /// igual que en [AccountFormTab], el HomeShell mantiene esta pestaña
  /// siempre montada en el `IndexedStack` aunque todavía no se haya
  /// abierto desde ninguna tarjeta.
  final Account? account;

  /// Vuelve a la vista general de "Cuentas", de donde siempre se abre
  /// esta pantalla.
  final VoidCallback onDone;

  const UpdateBalanceTab({
    super.key,
    required this.account,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final accountName = account?.name;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text('Actualizar saldo', style: AppTextStyles.authTitle),
          const SizedBox(height: 8),
          Text(
            accountName == null
                ? 'Cargá el saldo actual de la cuenta.'
                : 'Cargá el saldo actual de "$accountName".',
            style: AppTextStyles.authSubtitle,
          ),
        ],
      ),
    );
  }
}
