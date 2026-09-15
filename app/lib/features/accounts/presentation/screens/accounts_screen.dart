import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/account_visuals.dart';
import '../../../../core/utils/category_visuals.dart' show colorFromHex;
import '../../../../core/utils/currency_format.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import 'account_form_screen.dart';

class AccountsScreen extends StatelessWidget {
  final String userId;
  final AccountViewModel accountViewModel;

  const AccountsScreen({
    super.key,
    required this.userId,
    required this.accountViewModel,
  });

  Future<void> _openForm(BuildContext context, {Account? account}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          userId: userId,
          accountViewModel: accountViewModel,
          account: account,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
      appBar: AppBar(
        backgroundColor: AppColors.authBackgroundBottom,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.authTextPrimary),
        title: const Text(
          'Cuentas',
          style: TextStyle(
            color: AppColors.authTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.authAccent,
        foregroundColor: AppColors.authBackgroundBottom,
        child: const Icon(Icons.add_rounded),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.authBackgroundTop,
              AppColors.authBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: accountViewModel,
            builder: (context, _) {
              if (accountViewModel.isLoading &&
                  accountViewModel.accounts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.authAccent),
                );
              }

              final accounts = accountViewModel.accounts;

              if (accounts.isEmpty) {
                return const Center(
                  child: Text(
                    'Todavía no hay cuentas.\nTocá + para crear la primera.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSubtitle,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                children: [
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
                          onTap: () => _openForm(context, account: account),
                          showDivider: i != accounts.length - 1,
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  final bool showDivider;

  const _AccountRow({
    required this.account,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(account.color, fallback: AppColors.authAccent);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.85),
                  child: Icon(accountIconFromName(account.icon),
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.authTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCurrency(account.balance, account.currency),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.authTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.authTextFooter),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}
