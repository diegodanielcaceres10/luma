import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';
import '../view_models/monthly_balance_view_model.dart';
import '../widgets/account_trend_section.dart';
import '../widgets/month_variation_indicator.dart';

enum _AccountAction { edit, updateBalance, justifyUncontrolled }

const _kWarningColor = Color(0xFFFBBF24);

class AccountViewScreen extends StatefulWidget {
  final Account account;
  final AccountViewModel accountViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final VoidCallback onEdit;
  final VoidCallback onUpdateBalance;
  final VoidCallback onJustifyUncontrolled;

  /// Opens the opening balance flow, from the missing-balance banner.
  final VoidCallback onCompleteBalance;
  final VoidCallback onBack;

  const AccountViewScreen({
    super.key,
    required this.account,
    required this.accountViewModel,
    required this.monthlyBalanceViewModel,
    required this.onEdit,
    required this.onUpdateBalance,
    required this.onJustifyUncontrolled,
    required this.onCompleteBalance,
    required this.onBack,
  });

  @override
  State<AccountViewScreen> createState() => _AccountViewScreenState();
}

class _AccountViewScreenState extends State<AccountViewScreen> {
  @override
  void initState() {
    super.initState();
    widget.accountViewModel.loadUncontrolledTotal(widget.account.id);
    widget.accountViewModel.loadOpeningHistory(widget.account.id);
  }

  Account _currentAccount() {
    for (final a in widget.accountViewModel.accounts) {
      if (a.id == widget.account.id) return a;
    }
    return widget.account;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.accountViewModel,
          widget.monthlyBalanceViewModel,
        ]),
        builder: (context, _) {
          final current = _currentAccount();
          // Unknown until the monthly check runs, so nothing is flagged by
          // mistake while it loads or fails.
          final isPending = widget.monthlyBalanceViewModel.checked &&
              current.isActive &&
              widget.monthlyBalanceViewModel.isAccountPending(current.id);
          final currency = widget.accountViewModel.primaryCurrency;
          final uncontrolled =
              widget.accountViewModel.uncontrolledTotalOf(current.id);
          final hasUncontrolled = uncontrolled.abs() >= 0.005;
          final variation =
              widget.accountViewModel.monthVariationOf(current.id);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  ScreenHeader(
                    title: current.name,
                    size: ScreenHeaderSize.compact,
                    onBack: widget.onBack,
                    action: HeaderMenuButton<_AccountAction>(
                      items: [
                        const HeaderMenuItem(
                          value: _AccountAction.edit,
                          label: 'Editar cuenta',
                          icon: Icons.edit_rounded,
                        ),
                        const HeaderMenuItem(
                          value: _AccountAction.updateBalance,
                          label: 'Actualizar saldo',
                          icon: Icons.sync_rounded,
                        ),
                        if (hasUncontrolled)
                          const HeaderMenuItem(
                            value: _AccountAction.justifyUncontrolled,
                            label: 'Justificar gastos',
                            icon: Icons.fact_check_rounded,
                          ),
                      ],
                      onSelected: (action) => switch (action) {
                        _AccountAction.edit => widget.onEdit(),
                        _AccountAction.updateBalance => widget.onUpdateBalance(),
                        _AccountAction.justifyUncontrolled =>
                          widget.onJustifyUncontrolled(),
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isPending) ...[
                    _MissingOpeningBalanceBanner(
                      onCompleteBalance: widget.onCompleteBalance,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _HeroBalanceCard(
                    current: current,
                    currency: currency,
                    variation: variation,
                    uncontrolled: uncontrolled,
                    hasUncontrolled: hasUncontrolled,
                    onJustifyUncontrolled: widget.onJustifyUncontrolled,
                    onToggleActive: (value) =>
                        widget.accountViewModel.toggleActive(
                      current.id,
                      value,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AccountTrendSection(
                    history:
                        widget.accountViewModel.openingHistoryOf(current.id),
                    currentBalance: current.balance,
                    currency: currency,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MissingOpeningBalanceBanner extends StatelessWidget {
  final VoidCallback onCompleteBalance;

  const _MissingOpeningBalanceBanner({required this.onCompleteBalance});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kWarningColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kWarningColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kWarningColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: _kWarningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Falta cerrar el mes anterior',
                      style: TextStyle(
                        color: _kWarningColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Registrá y cerrá el mes anterior antes de continuar '
                      'con el saldo del nuevo mes.',
                      style: TextStyle(
                        color: AppColors.authTextSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onCompleteBalance,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kWarningColor,
                side: BorderSide(color: _kWarningColor.withValues(alpha: 0.4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cargar saldo inicial',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  final Account current;
  final String currency;
  final double? variation;
  final double uncontrolled;
  final bool hasUncontrolled;
  final VoidCallback onJustifyUncontrolled;
  final ValueChanged<bool> onToggleActive;

  const _HeroBalanceCard({
    required this.current,
    required this.currency,
    required this.variation,
    required this.uncontrolled,
    required this.hasUncontrolled,
    required this.onJustifyUncontrolled,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current.isActive;

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
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.authAccent.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isActive
                        ? AppColors.authAccent.withValues(alpha: 0.30)
                        : AppColors.authCardBorder,
                  ),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: isActive
                      ? AppColors.authAccent
                      : AppColors.authTextSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo actual',
                      style: TextStyle(
                        color: AppColors.authTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Última actualización: '
                      '${formatDateTime(current.balanceUpdatedAt)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.authTextFooter,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.authAccent.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.authAccent.withValues(alpha: 0.3)
                        : AppColors.authCardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.authAccent
                            : AppColors.authTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.authAccent
                            : AppColors.authTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            formatCurrency(current.balance, currency),
            style: const TextStyle(
              color: AppColors.authTextPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          if (variation != null) ...[
            const SizedBox(height: 10),
            MonthVariationIndicator(
              variation: variation!,
              currency: currency,
            ),
          ],
          if (hasUncontrolled) ...[
            const SizedBox(height: 18),
            _UncontrolledMovementBanner(
              uncontrolled: uncontrolled,
              currency: currency,
              onJustify: onJustifyUncontrolled,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.authCardBorder),
          const SizedBox(height: 10),
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
              const SizedBox(width: 8),
              Text(
                current.isActive ? 'Cuenta activa' : 'Cuenta inactiva',
                style: const TextStyle(
                  color: AppColors.authTextSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Switch(
                value: current.isActive,
                activeThumbColor: AppColors.authAccent,
                activeTrackColor: AppColors.authAccent.withValues(alpha: 0.35),
                onChanged: onToggleActive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UncontrolledMovementBanner extends StatelessWidget {
  final double uncontrolled;
  final String currency;
  final VoidCallback onJustify;

  const _UncontrolledMovementBanner({
    required this.uncontrolled,
    required this.currency,
    required this.onJustify,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = uncontrolled < 0;
    final bannerColor =
        isExpense ? AppColors.authExpense : AppColors.authIncome;
    final label = isExpense
        ? 'Gasto sin declarar este mes'
        : 'Ingreso sin declarar este mes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpense
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color: bannerColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(uncontrolled, currency),
                  style: TextStyle(
                    color: bannerColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onJustify,
            style: OutlinedButton.styleFrom(
              foregroundColor: bannerColor,
              side: BorderSide(color: bannerColor.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Justificar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
