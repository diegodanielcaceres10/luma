import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Contenido de la pestaña "Cuentas": resumen de saldos y las cuentas en
/// lista. Cada fila solo lleva al detalle de la cuenta (ver [_AccountRow]).
///
/// Entrega 14: unifica lo que antes eran dos pantallas separadas
/// (`AccountsTab`, sin resumen ni botón "atrás", con edición; y esta
/// misma, con resumen y botón "atrás", sin edición) en una sola — misma
/// visual para las dos rutas que la abren, [onBack] es lo único que
/// cambia entre ellas:
/// - `/accounts` (pestaña del drawer): sin [onBack] — no hay a dónde
///   volver, es una pestaña de primer nivel.
/// - `/accounts-overview` (push desde el Dashboard, "Gestionar cuentas"):
///   con [onBack] — vuelve al Dashboard.
///
/// Entrega 15: agrega [AccountViewScreen] — tocar una fila ya no va
/// directo a editar, va al detalle de esa cuenta, desde donde también se
/// puede editar y actualizar el saldo (ver [onOpenView]).
///
/// Entrega 16: la fila deja de tener atajos propios (lápiz de edición,
/// ícono de actualizar saldo y switch de activa/inactiva): todo eso vive
/// ahora únicamente en [AccountViewScreen], y la fila solo lleva hasta
/// ahí. Por eso ya no existe `onOpenUpdateBalance` en esta clase.
///
/// No tiene Scaffold propio — se muestra dentro de un RoutedScreenScaffold,
/// debajo del header (menú + marca Luma + campana) y encima del
/// bottomNavigationBar que pone AppShellScreen.
class AccountsOverviewTab extends StatelessWidget {
  final AccountViewModel accountViewModel;

  /// Abre el detalle de esa cuenta ([AccountViewScreen]) — se llama al
  /// tocar la fila (ver [_AccountRow.onView]). Es la única acción de la
  /// fila.
  final ValueChanged<Account> onOpenView;

  /// Abre el formulario de cuenta ([AccountFormTab]) para un alta nueva
  /// (botón "+" del título, siempre con `null`). La edición de una cuenta
  /// existente ya no pasa por acá: se abre desde el botón "Editar cuenta"
  /// de [AccountViewScreen].
  final ValueChanged<Account?> onOpenForm;

  /// Vuelve a la pantalla desde la que se abrió esta vista. `null` cuando
  /// esta vista es la pestaña de primer nivel "Cuentas" (no hay a dónde
  /// volver) — en ese caso no se dibuja el botón "atrás".
  final VoidCallback? onBack;

  const AccountsOverviewTab({
    super.key,
    required this.accountViewModel,
    required this.onOpenView,
    required this.onOpenForm,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: accountViewModel,
        builder: (context, _) {
          final accounts = accountViewModel.accounts;
          final currency = accountViewModel.primaryCurrency;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  if (onBack != null) ...[
                    InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppColors.authTextPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text('Cuentas', style: AppTextStyles.authTitle),
                  const Spacer(),
                  IconButton(
                    onPressed: () => onOpenForm(null),
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.authTextPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestiona tus cuentas, actualiza saldos y mantén todo en '
                'orden.',
                style: AppTextStyles.authSubtitle,
              ),
              const SizedBox(height: 24),
              _TotalCard(
                isLoading: accountViewModel.isLoading,
                total: accountViewModel.totalBalance,
                currency: currency,
              ),
              const SizedBox(height: 20),
              if (accountViewModel.isLoading && accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.authAccent,
                    ),
                  ),
                )
              else if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'Todavía no hay cuentas.\nTocá + para crear la primera.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSubtitle,
                  ),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.authCardFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.authCardBorder),
                  ),
                  child: Column(
                    children: List.generate(accounts.length, (i) {
                      final account = accounts[i];
                      return _AccountRow(
                        account: account,
                        currency: currency,
                        onView: () => onOpenView(account),
                        showDivider: i != accounts.length - 1,
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final bool isLoading;
  final double total;
  final String currency;

  const _TotalCard({
    required this.isLoading,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.authAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total en cuentas',
                  style: TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.authAccent,
                        ),
                      )
                    : Text(
                        formatCurrency(total, currency),
                        style: const TextStyle(
                          color: AppColors.authTextPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
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

/// Fila de una cuenta en la lista: nombre, "Cuenta activa/inactiva" (solo
/// informativo) y saldo. Tocar cualquier parte de la fila llama a
/// [onView] (abre [AccountViewScreen]) — no tiene otras acciones: editar,
/// actualizar el saldo y activar/desactivar se hacen desde el detalle.
class _AccountRow extends StatelessWidget {
  final Account account;
  final String currency;
  final VoidCallback onView;
  final bool showDivider;

  const _AccountRow({
    required this.account,
    required this.currency,
    required this.onView,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = account.isActive;

    return Column(
      children: [
        Opacity(
          opacity: isActive ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: onView,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isActive ? 'Cuenta activa' : 'Cuenta inactiva',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.authTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatCurrency(account.balance, currency),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}
