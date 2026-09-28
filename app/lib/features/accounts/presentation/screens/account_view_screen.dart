import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Opciones del menú de tres puntos del header de [AccountViewScreen].
enum _AccountAction { edit, updateBalance }

/// Detalle de una cuenta: sus datos (nombre, saldo, estado) y, desde el
/// menú de tres puntos del header ([HeaderMenuButton]), entrar a editarla
/// ([AccountFormTab], "Editar cuenta") o actualizar su saldo
/// ([UpdateBalanceTab], "Actualizar saldo").
///
/// Se llega tocando una fila en [AccountsOverviewTab], que no tiene otros
/// atajos: editar y actualizar el saldo se hacen únicamente desde el menú
/// de esta pantalla, y el estado activa/inactiva desde su `Switch`.
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
              ScreenHeader(
                title: current.name,
                size: ScreenHeaderSize.compact,
                onBack: onBack,
                action: HeaderMenuButton<_AccountAction>(
                  items: const [
                    HeaderMenuItem(
                      value: _AccountAction.edit,
                      label: 'Editar cuenta',
                      icon: Icons.edit_rounded,
                    ),
                    HeaderMenuItem(
                      value: _AccountAction.updateBalance,
                      label: 'Actualizar saldo',
                      icon: Icons.sync_rounded,
                    ),
                  ],
                  onSelected: (action) => switch (action) {
                    _AccountAction.edit => onEdit(),
                    _AccountAction.updateBalance => onUpdateBalance(),
                  },
                ),
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
            ],
          );
        },
      ),
    );
  }
}
