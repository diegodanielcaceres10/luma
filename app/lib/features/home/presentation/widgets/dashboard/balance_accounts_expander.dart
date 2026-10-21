import 'package:flutter/material.dart';

import '../../../../../core/utils/currency_format.dart';
import '../../../../accounts/data/models/account.dart';

/// Expandable part of the [DashboardBalanceCard]: a chevron at the bottom of the
/// card that, when tapped, shows each account's balance; tapping an account
/// opens it. Starts collapsed and its state is not kept between sessions.
class BalanceAccountsExpander extends StatefulWidget {
  final List<Account> accounts;
  final String currency;
  final ValueChanged<String> onOpenAccount;
  final Set<String> pendingAccountIds;
  final ValueChanged<String> onCompletePendingBalance;

  const BalanceAccountsExpander({
    super.key,
    required this.accounts,
    required this.currency,
    required this.onOpenAccount,
    required this.pendingAccountIds,
    required this.onCompletePendingBalance,
  });

  @override
  State<BalanceAccountsExpander> createState() =>
      _BalanceAccountsExpanderState();
}

class _BalanceAccountsExpanderState extends State<BalanceAccountsExpander> {
  static const _animationDuration = Duration(milliseconds: 250);

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: _animationDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? _buildAccounts()
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 10),
        Center(
          child: Semantics(
            button: true,
            label: _expanded ? 'Ocultar cuentas' : 'Ver cuentas',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Ocultar cuentas' : 'Ver cuentas',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: _animationDuration,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 14),
        const Text(
          'Saldo por cuenta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        for (final account in widget.accounts)
          _AccountBalanceRow(
            account: account,
            currency: widget.currency,
            isPending: widget.pendingAccountIds.contains(account.id),
            onOpen: () => widget.onOpenAccount(account.id),
            onCompletePendingBalance: () =>
                widget.onCompletePendingBalance(account.id),
          ),
      ],
    );
  }
}

/// One account of the expanded breakdown: name and balance, which opens the
/// account when tapped, plus a link to load its opening balance when it is
/// still missing this month.
class _AccountBalanceRow extends StatelessWidget {
  final Account account;
  final String currency;
  final bool isPending;
  final VoidCallback onOpen;
  final VoidCallback onCompletePendingBalance;

  const _AccountBalanceRow({
    required this.account,
    required this.currency,
    required this.isPending,
    required this.onOpen,
    required this.onCompletePendingBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The warning below has its own action, so only this line opens
            // the account.
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white70,
                          size: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatCurrency(account.balance, currency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCompletePendingBalance,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            const Color(0xFFFBBF24).withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFBBF24),
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Falta cargar el saldo inicial',
                            style: TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFFBBF24),
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
