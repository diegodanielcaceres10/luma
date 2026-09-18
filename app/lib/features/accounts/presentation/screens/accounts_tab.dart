import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Contenido de la pestaña "Cuentas". No tiene Scaffold propio — vive dentro
/// del Scaffold del HomeShell, que es quien pone el header y el
/// bottomNavigationBar.
class AccountsTab extends StatelessWidget {
  final AccountViewModel accountViewModel;

  /// Pide al HomeShell que muestre la pestaña de formulario. `null` = alta
  /// nueva; con valor = edición de esa cuenta.
  final ValueChanged<Account?> onOpenForm;

  const AccountsTab({
    super.key,
    required this.accountViewModel,
    required this.onOpenForm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: accountViewModel,
        builder: (context, _) {
          if (accountViewModel.isLoading && accountViewModel.accounts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.authAccent),
            );
          }

          final accounts = accountViewModel.accounts;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const Text(
                'Cuentas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
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
                        currency: accountViewModel.primaryCurrency,
                        onTap: () => onOpenForm(account),
                        onActiveChanged: (value) =>
                            accountViewModel.toggleActive(account.id, value),
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

class _AccountRow extends StatelessWidget {
  final Account account;
  final String currency;
  final VoidCallback onTap;
  final ValueChanged<bool> onActiveChanged;
  final bool showDivider;

  const _AccountRow({
    required this.account,
    required this.currency,
    required this.onTap,
    required this.onActiveChanged,
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
            onTap: onTap,
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
                          formatCurrency(account.balance, currency),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.authTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        activeTrackColor: AppColors.authAccent,
                        onChanged: onActiveChanged,
                      ),
                      Text(
                        isActive ? 'Activa' : 'Inactiva',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.authTextFooter,
                        ),
                      ),
                    ],
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
