import 'package:flutter/material.dart';

import '../../../../../core/utils/currency_format.dart';
import '../../../../accounts/data/models/account.dart';

/// Expandable part of the [DashboardBalanceCard]: a chevron at the bottom of the
/// card that, when tapped, shows each account's balance and the link to
/// account settings. Starts collapsed and its state is not kept between
/// sessions.
class BalanceAccountsExpander extends StatefulWidget {
  final List<Account> accounts;
  final String currency;
  final VoidCallback onManageAccounts;
  final Set<String> pendingAccountIds;
  final ValueChanged<String> onCompletePendingBalance;

  const BalanceAccountsExpander({
    super.key,
    required this.accounts,
    required this.currency,
    required this.onManageAccounts,
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
        Center(
          child: Semantics(
            button: true,
            label: _expanded ? 'Ocultar cuentas' : 'Ver cuentas',
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: _animationDuration,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 28,
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
        const SizedBox(height: 8),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Saldo por cuenta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            InkWell(
              onTap: widget.onManageAccounts,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.settings, color: Colors.white70, size: 30),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (final account in widget.accounts)
          _AccountBalanceRow(
            account: account,
            currency: widget.currency,
            isPending: widget.pendingAccountIds.contains(account.id),
            onCompletePendingBalance: () =>
                widget.onCompletePendingBalance(account.id),
          ),
      ],
    );
  }
}

/// One account of the expanded breakdown: name and balance, plus a link to
/// load its opening balance when it is still missing this month.
class _AccountBalanceRow extends StatelessWidget {
  final Account account;
  final String currency;
  final bool isPending;
  final VoidCallback onCompletePendingBalance;

  const _AccountBalanceRow({
    required this.account,
    required this.currency,
    required this.isPending,
    required this.onCompletePendingBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
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
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: onCompletePendingBalance,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Falta cargar el saldo inicial',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
