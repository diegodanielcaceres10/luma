import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../auth/presentation/view_models/preferences_view_model.dart';
import '../../../notifications/presentation/widgets/notifications_hint.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

class AccountsScreen extends StatelessWidget {
  final AccountViewModel accountViewModel;
  final PreferencesViewModel preferencesViewModel;

  final ValueChanged<Account> onOpenView;

  final VoidCallback onOpenForm;

  /// Opens Preferencias, from the notifications hint.
  final VoidCallback onOpenPreferences;

  final VoidCallback? onBack;

  const AccountsScreen({
    super.key,
    required this.accountViewModel,
    required this.preferencesViewModel,
    required this.onOpenView,
    required this.onOpenForm,
    required this.onOpenPreferences,
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

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScreenHeader(
                    title: 'Cuentas',
                    subtitle: 'Gestiona tus cuentas, actualiza saldos y mantén '
                        'todo en orden.',
                    size: ScreenHeaderSize.compact,
                    onBack: onBack,
                    action: HeaderAddButton(
                      tooltip: 'Nueva cuenta',
                      onPressed: onOpenForm,
                    ),
                  ),
                  const SizedBox(height: 12),
                  NotificationsHint(
                    preferencesViewModel: preferencesViewModel,
                    onOpenPreferences: onOpenPreferences,
                  ),
                  const SizedBox(height: 20),
                  _TotalCard(
                    isLoading: accountViewModel.isLoading,
                    total: accountViewModel.totalBalance,
                    currency: currency,
                  ),
                  const SizedBox(height: 24),
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
                    _EmptyAccountsCard(onOpenForm: onOpenForm)
                  else ...[
                    _SectionLabel('Tus cuentas (${accounts.length})'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.authCardFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.authCardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.authTextSecondary,
        ),
      ),
    );
  }
}

class _EmptyAccountsCard extends StatelessWidget {
  final VoidCallback onOpenForm;

  const _EmptyAccountsCard({required this.onOpenForm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              size: 28,
              color: AppColors.authAccent,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Todavía no hay cuentas.\nTocá + para crear la primera.',
            textAlign: TextAlign.center,
            style: AppTextStyles.authSubtitle,
          ),
        ],
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.authAccent.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.authAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total en cuentas',
                  style: TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
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
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
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
          opacity: isActive ? 1.0 : 0.55,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onView,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.authAccent.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isActive
                              ? AppColors.authAccent.withValues(alpha: 0.28)
                              : AppColors.authCardBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        size: 20,
                        color: isActive
                            ? AppColors.authAccent
                            : AppColors.authTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? AppColors.authAccent
                                      : AppColors.authTextSecondary
                                          .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive ? 'Cuenta activa' : 'Cuenta inactiva',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isActive
                                      ? AppColors.authTextSecondary
                                      : AppColors.authTextFooter,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Actualizada: '
                            '${formatDateTime(account.balanceUpdatedAt)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.authTextFooter,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatCurrency(account.balance, currency),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.authTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: AppColors.authCardBorder,
          ),
      ],
    );
  }
}
