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

/// Row width under which the balance goes below the name. Next to the
/// balance, icon, chevron and padding, a narrower row leaves the name with
/// almost no room.
const double _kCompactRowWidth = 330;

/// One account of the expanded breakdown: icon, name, a warning when its
/// opening balance is still missing this month, balance and chevron. Tapping
/// the row opens the account; tapping the warning loads the opening balance.
///
/// On very narrow screens the balance moves under the name so the name keeps
/// the room it needs.
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _kCompactRowWidth;

          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: compact ? _buildCompact() : _buildRegular(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegular() {
    return Row(
      children: [
        const _AccountIcon(),
        const SizedBox(width: 10),
        Expanded(child: _name(maxLines: 1)),
        if (isPending) ...[
          const SizedBox(width: 8),
          _warning(),
        ],
        const SizedBox(width: 8),
        _balance(),
        const SizedBox(width: 4),
        const _Chevron(),
      ],
    );
  }

  Widget _buildCompact() {
    return Row(
      children: [
        const _AccountIcon(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _name(maxLines: 2),
              const SizedBox(height: 2),
              // Scales down instead of wrapping "USD" onto its own line.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _balance(),
              ),
            ],
          ),
        ),
        if (isPending) ...[
          const SizedBox(width: 4),
          _warning(),
        ],
        const SizedBox(width: 4),
        const _Chevron(),
      ],
    );
  }

  Widget _name({required int maxLines}) {
    return Text(
      account.name,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _balance() {
    return Text(
      formatCurrency(account.balance, currency),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  Widget _warning() {
    return Semantics(
      button: true,
      label: 'Falta cargar el saldo inicial',
      child: InkWell(
        onTap: onCompletePendingBalance,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFBBF24),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _AccountIcon extends StatelessWidget {
  const _AccountIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right_rounded,
      color: Colors.white54,
      size: 20,
    );
  }
}
