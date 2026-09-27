import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Detalle de una cuenta: sus datos (nombre, saldo, estado) y, desde acá,
/// entrar a editarla ([AccountFormTab], botón "Editar cuenta") o
/// actualizar su saldo ([UpdateBalanceTab], botón "Actualizar saldo").
///
/// Se llega tocando una fila en [AccountsOverviewTab] (el lápiz y el
/// ícono de sync de esa fila siguen siendo atajos directos a
/// edición/actualización sin pasar por acá — ver su doc; esta pantalla es
/// la vista completa, con esos mismos dos accesos más el estado
/// activa/inactiva).
///
/// [account] es la foto de la cuenta al momento de navegar acá (la
/// resuelve `_accountGuard` en router.dart, una sola vez — no se
/// actualiza sola). Como se puede volver a esta pantalla después de
/// editar o actualizar el saldo (al hacer "atrás" desde esos formularios,
/// esta sigue siendo la misma instancia en la pila de navegación), esta
/// clase vuelve a buscarla por id en [accountViewModel] en cada rebuild
/// (ver [_currentAccount]) para no quedarse mostrando datos viejos.
///
/// No tiene Scaffold propio — se muestra dentro de un RoutedScreenScaffold,
/// debajo del header y encima del bottomNavigationBar que pone
/// AppShellScreen.
class AccountViewScreen extends StatelessWidget {
  final Account account;
  final AccountViewModel accountViewModel;
  final VoidCallback onEdit;
  final VoidCallback onUpdateBalance;
  final VoidCallback onBack;

  const AccountViewScreen({
    super.key,
    required this.account,
    required this.accountViewModel,
    required this.onEdit,
    required this.onUpdateBalance,
    required this.onBack,
  });

  /// Ver el doc de la clase: [account] puede haber quedado vieja si se
  /// volvió acá después de editar o actualizar el saldo, así que se
  /// busca de nuevo por id en la lista actual del view model. Si ya no
  /// está (se borró desde otro lado), se muestra la última foto conocida
  /// en vez de romper — `_accountGuard` se encarga de sacar de acá si
  /// corresponde.
  Account _currentAccount() {
    for (final a in accountViewModel.accounts) {
      if (a.id == account.id) return a;
    }
    return account;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: accountViewModel,
        builder: (context, _) {
          final current = _currentAccount();
          final currency = accountViewModel.primaryCurrency;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      current.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.authCardFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.authCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo actual',
                      style: TextStyle(
                        color: AppColors.authTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(current.balance, currency),
                      style: const TextStyle(
                        color: AppColors.authTextPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          current.isActive
                              ? Icons.check_circle_rounded
                              : Icons.pause_circle_rounded,
                          size: 18,
                          color: current.isActive
                              ? AppColors.authAccent
                              : AppColors.authTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          current.isActive
                              ? 'Cuenta activa'
                              : 'Cuenta inactiva',
                          style: const TextStyle(
                            color: AppColors.authTextSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: current.isActive,
                          activeTrackColor: AppColors.authAccent,
                          onChanged: (value) => accountViewModel.toggleActive(
                            current.id,
                            value,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar cuenta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.authTextPrimary,
                  side: const BorderSide(color: AppColors.authCardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onUpdateBalance,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Actualizar saldo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.authAccent,
                  foregroundColor: AppColors.authBackgroundBottom,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
