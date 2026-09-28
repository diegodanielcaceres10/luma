import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

enum _AccountAction { edit, updateBalance }

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
