import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/category_visuals.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Íconos genéricos que se van alternando entre cuentas. A diferencia de
/// las categorías, las cuentas no guardan un ícono ni un color propio en
/// la base (ver `db/migrations`), así que no hay forma de replicar el
/// logo/color de cada banco del prototipo — se asigna una variante fija
/// por posición, solo para diferenciar visualmente las tarjetas.
const _kAccountIcons = [
  Icons.account_balance_wallet_rounded,
  Icons.credit_card_rounded,
  Icons.savings_rounded,
  Icons.account_balance_rounded,
];

/// Contenido de la pestaña "Cuentas" (vista general), basada en el
/// prototipo con el resumen de saldos y las cuentas en tarjetas.
///
/// No tiene Scaffold propio — vive dentro del Scaffold del HomeShell, que es
/// quien pone el header (menú + marca Luma + campana) y el
/// bottomNavigationBar.
class AccountsOverviewTab extends StatelessWidget {
  final AccountViewModel accountViewModel;

  /// Pide al HomeShell que muestre la pestaña de formulario. `null` = alta
  /// nueva; con valor = edición de esa cuenta. Mismo contrato que
  /// [AccountsTab.onOpenForm].
  final ValueChanged<Account?> onOpenForm;

  /// Pide al HomeShell que abra la nueva pantalla de actualización rápida
  /// de saldo para esta cuenta (distinta del formulario de edición).
  final ValueChanged<Account> onOpenUpdateBalance;

  const AccountsOverviewTab({
    super.key,
    required this.accountViewModel,
    required this.onOpenForm,
    required this.onOpenUpdateBalance,
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
              const Text('Cuentas', style: AppTextStyles.authTitle),
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
                    'Todavía no hay cuentas.\nTocá "Agregar cuenta" para '
                    'crear la primera.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSubtitle,
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    ...List.generate(accounts.length, (i) {
                      final account = accounts[i];
                      return _AccountCard(
                        account: account,
                        currency: currency,
                        color: colorFromHex(
                          kCategoryColors[i % kCategoryColors.length],
                        ),
                        icon: _kAccountIcons[i % _kAccountIcons.length],
                        onTap: () => onOpenForm(account),
                        onUpdateBalance: () => onOpenUpdateBalance(account),
                      );
                    }),
                    _AddAccountCard(onTap: () => onOpenForm(null)),
                  ],
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

class _AccountCard extends StatelessWidget {
  final Account account;
  final String currency;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onUpdateBalance;

  const _AccountCard({
    required this.account,
    required this.currency,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.onUpdateBalance,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = account.isActive;

    // No se puede combinar un Border con colores distintos por lado (el
    // acento a la izquierda, el borde tenue en el resto) con borderRadius
    // — Flutter lo exige uniforme. En su lugar, la franja de color va como
    // un Container aparte dentro del Row, y el redondeo lo da el ClipRRect
    // que envuelve toda la tarjeta.
    return Opacity(
      opacity: isActive ? 1 : 0.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.authCardFill),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const Spacer(),
                            // Ícono de actualización de saldo (no de
                            // edición): abre una pantalla nueva, aparte,
                            // pensada solo para cargar el saldo actual.
                            IconButton(
                              onPressed: onUpdateBalance,
                              icon: Icon(Icons.sync_alt_rounded,
                                  color: color, size: 18),
                              tooltip: 'Actualizar saldo',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isActive ? 'Cuenta activa' : 'Cuenta inactiva',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.authTextSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatCurrency(account.balance, currency),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.authAccent.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.authAccent),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.authAccent,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agregar cuenta',
                style: TextStyle(
                  color: AppColors.authAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
