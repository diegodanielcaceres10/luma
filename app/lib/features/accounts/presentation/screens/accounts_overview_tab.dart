import 'package:flutter/material.dart';

import '../../../../app/theme/app_text_styles.dart';

/// Contenido de la nueva pestaña "Cuentas" (vista general), basada en el
/// prototipo con el resumen de saldos y las cuentas en tarjetas.
///
/// No tiene Scaffold propio — vive dentro del Scaffold del HomeShell, que es
/// quien pone el header (menú + marca Luma + campana) y el
/// bottomNavigationBar.
///
/// Por ahora solo está desarrollado el header propio de la pantalla (título
/// y bajada); el resto del prototipo (tarjeta de total, grilla de cuentas y
/// "Agregar cuenta") queda para una próxima entrega.
class AccountsOverviewTab extends StatelessWidget {
  const AccountsOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: const [
          Text(
            'Cuentas',
            style: AppTextStyles.authTitle,
          ),
          SizedBox(height: 8),
          Text(
            'Gestiona tus cuentas, actualiza saldos y mantén todo en orden.',
            style: AppTextStyles.authSubtitle,
          ),
        ],
      ),
    );
  }
}
