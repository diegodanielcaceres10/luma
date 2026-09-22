import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Contenido de la pestaña "Cuentas" (vista general), con el resumen de
/// saldos y las cuentas en lista — mismo patrón que [AccountsTab], pero
/// acá cada fila lleva a actualizar el saldo en vez de editar la cuenta.
///
/// No tiene Scaffold propio — se muestra dentro de un RoutedScreenScaffold,
/// debajo del header (menú + marca Luma + campana) y encima del
/// bottomNavigationBar que pone AppShellScreen.
class AccountsOverviewTab extends StatelessWidget {
  final AccountViewModel accountViewModel;

  /// Abre el formulario de cuenta. Acá solo se usa para alta nueva (se
  /// llama con `null`) — la edición se sacó de esta vista, queda nada
  /// más en "Cuentas" (ver [AccountsTab.onOpenForm], mismo contrato).
  final ValueChanged<Account?> onOpenForm;

  /// Abre la pantalla de actualización rápida de saldo para esta cuenta
  /// (distinta del formulario de edición).
  final ValueChanged<Account> onOpenUpdateBalance;

  /// Vuelve a la pantalla desde la que se abrió esta vista (el Dashboard).
  final VoidCallback onBack;

  const AccountsOverviewTab({
    super.key,
    required this.accountViewModel,
    required this.onOpenForm,
    required this.onOpenUpdateBalance,
    required this.onBack,
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
                        onUpdateBalance: () => onOpenUpdateBalance(account),
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

class _AccountRow extends StatelessWidget {
  final Account account;
  final String currency;
  final VoidCallback onUpdateBalance;
  final bool showDivider;

  const _AccountRow({
    required this.account,
    required this.currency,
    required this.onUpdateBalance,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = account.isActive;

    return Column(
      children: [
        Opacity(
          opacity: isActive ? 1 : 0.5,
          child: InkWell(
            // Ya no hay edición desde acá (ver AccountsOverviewTab.onOpenForm):
            // toda la fila lleva a actualizar el saldo, no solo el ícono.
            onTap: onUpdateBalance,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency(account.balance, currency),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Solo indica que la fila lleva a actualizar el saldo —
                  // el tap real es de toda la fila (ver el onTap de arriba).
                  const Icon(
                    Icons.price_change_rounded,
                    color: AppColors.authAccent,
                    size: 20,
                  ),
                ],
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
