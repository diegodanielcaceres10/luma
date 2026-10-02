import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';

/// Content of the "Home" screen. It has no Scaffold of its own — it is
/// shown inside AppShellScreen's Scaffold, which provides the header and the
/// bottomNavigationBar.
///
/// Until all the initial data arrives it shows only a spinner. Afterwards,
/// depending on the active accounts, it shows the card to create the first
/// account or the rest of the content.
class DashboardScreen extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final VoidCallback? onSeeAllMovements;
  final ValueChanged<String> onOpenMonthlyBalance;
  final ValueChanged<String> onOpenAddTransaction;
  final VoidCallback onGoToAccounts;
  final VoidCallback onManageAccounts;
  final VoidCallback onGoToInvoices;
  final VoidCallback onGoToTransfers;

  const DashboardScreen({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.onOpenMonthlyBalance,
    required this.onOpenAddTransaction,
    required this.onGoToAccounts,
    required this.onManageAccounts,
    required this.onGoToInvoices,
    required this.onGoToTransfers,
    this.onSeeAllMovements,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Becomes true when the first load finishes and is never reverted: later
  // refreshes (e.g. after creating a movement) must not cover the dashboard
  // with the spinner — each section has its own spinners for that.
  bool _initialLoadDone = false;

  // To read where the floating button ended up and draw the overlay's "×"
  // exactly on top of it.
  final GlobalKey _fabKey = GlobalKey();

  /// `true` when all the data the dashboard uses has finished loading.
  /// Accounts are validated with `hasLoaded` because before loading starts
  /// `isLoading` is still false and the "no accounts" card would flash for an
  /// instant.
  bool get _isInitialLoadComplete =>
      widget.accountViewModel.hasLoaded &&
      !widget.accountViewModel.isLoading &&
      !widget.transactionViewModel.isLoading &&
      !widget.monthlyBalanceViewModel.isLoading &&
      !widget.invoiceViewModel.isLoading &&
      !widget.serviceViewModel.isLoading;

  void _retryLoad() {
    widget.accountViewModel.loadAccounts();
    widget.transactionViewModel.loadCurrentMonth();
    widget.monthlyBalanceViewModel.checkCurrentMonth();
    widget.invoiceViewModel.loadInvoices();
    widget.serviceViewModel.loadServices();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.accountViewModel,
        widget.transactionViewModel,
        widget.monthlyBalanceViewModel,
        widget.invoiceViewModel,
        widget.serviceViewModel,
      ]),
      builder: (context, _) {
        final accountViewModel = widget.accountViewModel;

        if (!_initialLoadDone && _isInitialLoadComplete) {
          _initialLoadDone = true;
        }

        // If accounts fail, `hasLoaded` is never reached; without this case the
        // spinner would spin forever.
        final loadFailed = !accountViewModel.hasLoaded &&
            !accountViewModel.isLoading &&
            accountViewModel.errorMessage != null;

        final Widget child;
        if (loadFailed) {
          child = _LoadErrorView(
            key: const ValueKey('dashboard-error'),
            onRetry: _retryLoad,
          );
        } else if (!_initialLoadDone) {
          child = const _DashboardLoading(key: ValueKey('dashboard-loading'));
        } else {
          final activeAccounts = accountViewModel.activeAccounts;
          child = activeAccounts.isEmpty
              ? _buildNoAccounts()
              : _buildContent(activeAccounts);
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }

  // No active accounts — guide the user to create one.
  Widget _buildNoAccounts() {
    return ListView(
      key: const ValueKey('dashboard-no-accounts'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _GreetingRow(
          initials: widget.authViewModel.initials,
          firstName: widget.authViewModel.displayName.split(' ').first,
        ),
        const SizedBox(height: 40),
        _NoAccountsCard(onGoToAccounts: widget.onGoToAccounts),
      ],
    );
  }

  /// Opens the quick actions menu: an overlay over the whole screen (root
  /// navigator, so it also covers the shell's header and bottom nav) with a
  /// blurred background and the 4 options.
  void _openQuickActions() {
    final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final fabRect = box.localToGlobal(Offset.zero) & box.size;
    final pendingInvoicesCount =
        widget.invoiceViewModel.pendingCountForCurrentMonth;

    final options = [
      _QuickActionOption(
        icon: Icons.arrow_upward_rounded,
        iconColor: AppColors.authExpense,
        title: 'Agregar gasto',
        subtitle: 'Registrá un nuevo gasto',
        onTap: () => widget.onOpenAddTransaction('expense'),
      ),
      _QuickActionOption(
        icon: Icons.arrow_downward_rounded,
        iconColor: AppColors.authIncome,
        title: 'Agregar ingreso',
        subtitle: 'Sumá dinero a tu cuenta',
        onTap: () => widget.onOpenAddTransaction('income'),
      ),
      _QuickActionOption(
        icon: Icons.request_page_outlined,
        iconColor: AppColors.authInvoice,
        title: 'Facturas por pagar',
        subtitle: pendingInvoicesCount > 0
            ? '$pendingInvoicesCount pendiente'
                '${pendingInvoicesCount == 1 ? '' : 's'} este mes'
            : 'Revisá el estado de tus facturas',
        onTap: widget.onGoToInvoices,
      ),
      _QuickActionOption(
        icon: Icons.swap_horiz_rounded,
        iconColor: AppColors.authTransfer,
        title: 'Transferencias entre cuentas',
        subtitle: 'Movés dinero de una cuenta a otra',
        onTap: widget.onGoToTransfers,
      ),
    ];

    showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Cerrar acciones rápidas',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      // The overlay animates its own blur, options and button with `animation`.
      transitionBuilder: (_, __, ___, child) => child,
      pageBuilder: (dialogContext, animation, _) => _QuickActionsOverlay(
        animation: animation,
        fabRect: fabRect,
        options: options,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Widget _buildContent(List<Account> activeAccounts) {
    final accountViewModel = widget.accountViewModel;
    final transactionViewModel = widget.transactionViewModel;
    final monthlyBalanceViewModel = widget.monthlyBalanceViewModel;

    final pendingAccounts = monthlyBalanceViewModel.checked
        ? monthlyBalanceViewModel.pendingAccounts(activeAccounts)
        : const <Account>[];

    final pendingInvoicesTotal = widget.invoiceViewModel
        .pendingAmountForCurrentMonth(widget.serviceViewModel.activeServices);
    final pendingInvoicesCount =
        widget.invoiceViewModel.pendingCountForCurrentMonth;

    return Stack(
      key: const ValueKey('dashboard-content'),
      children: [
        Positioned.fill(
          child: ListView(
            // Extra bottom padding so the floating button doesn't cover the last
            // movement.
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              _GreetingRow(
                initials: widget.authViewModel.initials,
                firstName: widget.authViewModel.displayName.split(' ').first,
              ),
              const SizedBox(height: 20),
              _BalanceCard(
                isLoading: accountViewModel.isLoading,
                total: accountViewModel.totalBalance,
                currency: accountViewModel.primaryCurrency,
                netResult: transactionViewModel.netResultWithUncontrolled,
                isLoadingNetResult: transactionViewModel.isLoading,
                pendingAccountIds: {
                  for (final account in pendingAccounts) account.id,
                },
                onCompletePendingBalance: widget.onOpenMonthlyBalance,
                onManageAccounts: widget.onManageAccounts,
                accounts: activeAccounts,
                pendingInvoicesTotal: pendingInvoicesTotal,
                pendingInvoicesCount: pendingInvoicesCount,
                isLoadingPendingInvoices: widget.invoiceViewModel.isLoading ||
                    widget.serviceViewModel.isLoading,
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Últimos movimientos',
                onSeeAll: widget.onSeeAllMovements,
              ),
              const SizedBox(height: 8),
              _RecentMovements(
                isLoading: transactionViewModel.isLoading,
                movements: transactionViewModel.recentMovements,
                currency: accountViewModel.primaryCurrency,
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: _AddFab(key: _fabKey, onPressed: _openQuickActions),
        ),
      ],
    );
  }
}

/// Centered spinner while the dashboard's initial data arrives.
class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.authAccent,
        ),
      ),
    );
  }
}

/// Shown if the accounts could not be loaded, so the spinner doesn't spin
/// forever or the "no accounts" card show up by mistake.
class _LoadErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.authTextSecondary,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar tus datos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.authAccent,
                foregroundColor: AppColors.authBackgroundBottom,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAccountsCard extends StatelessWidget {
  final VoidCallback onGoToAccounts;

  const _NoAccountsCard({required this.onGoToAccounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.authAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.authAccent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Creá tu primera cuenta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para empezar a registrar tus movimientos\nnecesitás al menos una cuenta activa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.authTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.authAccent,
                foregroundColor: AppColors.authBackgroundBottom,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onGoToAccounts,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear cuenta'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  final String initials;
  final String firstName;

  const _GreetingRow({required this.initials, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.authAccentDark.withValues(alpha: 0.35),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName 👋',
                style: AppTextStyles.authTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              const Text(
                'Aquí tienes un resumen de tus finanzas.',
                style: AppTextStyles.authSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isLoading;
  final double total;
  final String currency;

  /// Income minus expenses for the current month, plus that same month's
  /// undeclared adjustments (see
  /// [TransactionViewModel.netResultWithUncontrolled]).
  final double netResult;
  final bool isLoadingNetResult;

  /// Ids of the accounts without an opening balance this month.
  final Set<String> pendingAccountIds;
  final ValueChanged<String> onCompletePendingBalance;
  final VoidCallback onManageAccounts;

  /// Active accounts, for the breakdown that expands in the card.
  final List<Account> accounts;
  final double pendingInvoicesTotal;

  /// Pending invoices (neither paid nor cancelled) for the current month.
  final int pendingInvoicesCount;
  final bool isLoadingPendingInvoices;

  const _BalanceCard({
    required this.isLoading,
    required this.total,
    required this.currency,
    required this.netResult,
    required this.isLoadingNetResult,
    required this.onManageAccounts,
    required this.accounts,
    required this.onCompletePendingBalance,
    this.pendingAccountIds = const {},
    this.pendingInvoicesTotal = 0,
    this.pendingInvoicesCount = 0,
    this.isLoadingPendingInvoices = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/balance_card_bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  'Balance general del mes',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    formatCurrency(total, currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            const SizedBox(height: 8),
            isLoadingNetResult
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        netResult >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: netResult >= 0
                            ? AppColors.authAccent
                            : AppColors.authExpense,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${netResult >= 0 ? '+' : ''}'
                        '${formatCurrency(netResult, currency)} este mes',
                        style: TextStyle(
                          color: netResult >= 0
                              ? AppColors.authAccent
                              : AppColors.authExpense,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
            if (isLoadingPendingInvoices) ...[
              const SizedBox(height: 8),
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ] else ...[
              if (pendingInvoicesTotal > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Servicios pendientes de pagar: '
                        '${formatCurrency(pendingInvoicesTotal, currency)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (pendingInvoicesCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.request_page_outlined,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Facturas por pagar: $pendingInvoicesCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (pendingAccountIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _PendingBalancesAlert(count: pendingAccountIds.length),
            ],
            const SizedBox(height: 8),
            _BalanceAccountsExpander(
              accounts: accounts,
              currency: currency,
              onManageAccounts: onManageAccounts,
              pendingAccountIds: pendingAccountIds,
              onCompletePendingBalance: onCompletePendingBalance,
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable part of the [_BalanceCard]: a chevron at the bottom of the
/// card that, when tapped, shows each account's balance and the link to
/// account settings. Starts collapsed and its state is not kept between
/// sessions.
class _BalanceAccountsExpander extends StatefulWidget {
  final List<Account> accounts;
  final String currency;
  final VoidCallback onManageAccounts;
  final Set<String> pendingAccountIds;
  final ValueChanged<String> onCompletePendingBalance;

  const _BalanceAccountsExpander({
    required this.accounts,
    required this.currency,
    required this.onManageAccounts,
    required this.pendingAccountIds,
    required this.onCompletePendingBalance,
  });

  @override
  State<_BalanceAccountsExpander> createState() =>
      _BalanceAccountsExpanderState();
}

class _BalanceAccountsExpanderState extends State<_BalanceAccountsExpander> {
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

class _PendingBalancesAlert extends StatelessWidget {
  final int count;

  const _PendingBalancesAlert({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? 'Falta cargar el saldo inicial de 1 cuenta este mes'
        : 'Faltan cargar los saldos iniciales de $count cuentas este mes';

    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFFBBF24), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.authTextPrimary,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.authTextSecondary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ver todas', style: TextStyle(fontSize: 13)),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

/// One option of the quick actions menu.
class _QuickActionOption {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// Circular green floating button with a "+". The quick actions overlay
/// redraws it in the same position with [rotation] to turn it into an "×".
class _AddFab extends StatelessWidget {
  static const double size = 56;

  final VoidCallback onPressed;

  /// Icon rotation, in radians.
  final double rotation;

  const _AddFab({super.key, required this.onPressed, this.rotation = 0});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Acciones rápidas',
      child: Material(
        color: AppColors.authAccent,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black54,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.authBackgroundBottom,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick actions menu: blurred background over the whole screen, the
/// options stacked above the button and the button in place, now as an "×".
/// Tapping the background, the button or an option closes it.
class _QuickActionsOverlay extends StatelessWidget {
  final Animation<double> animation;

  /// Position of the floating button in screen coordinates.
  final Rect fabRect;
  final List<_QuickActionOption> options;
  final VoidCallback onClose;

  const _QuickActionsOverlay({
    required this.animation,
    required this.fabRect,
    required this.options,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeOut.transform(animation.value);

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.45 * t),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: screen.width - fabRect.right,
                bottom: screen.height - fabRect.top + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildOption(i),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: fabRect.left,
                top: fabRect.top,
                child: _AddFab(
                  rotation: t * math.pi / 4,
                  onPressed: onClose,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Staggered entrance: the option closest to the button appears first.
  Widget _buildOption(int index) {
    final option = options[index];
    final start = 0.1 * (options.length - 1 - index);
    final progress = Interval(
      start,
      start + 0.6,
      curve: Curves.easeOutCubic,
    ).transform(animation.value);

    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - progress)),
        child: _QuickActionPill(
          option: option,
          onTap: () {
            onClose();
            option.onTap();
          },
        ),
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  final _QuickActionOption option;
  final VoidCallback onTap;

  const _QuickActionPill({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authBackgroundTop,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.authCardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: AppTextStyles.authSubtitle.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              CircleAvatar(
                radius: 18,
                backgroundColor: option.iconColor.withValues(alpha: 0.85),
                child: Icon(option.icon, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMovements extends StatelessWidget {
  final bool isLoading;
  final List<TransactionEntry> movements;
  final String currency;

  const _RecentMovements({
    required this.isLoading,
    required this.movements,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (movements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Todavía no hay movimientos este mes.',
          style: AppTextStyles.authSubtitle,
        ),
      );
    }

    return Column(
      children: movements.map((m) {
        final sign = m.isIncome ? '+' : '-';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.description?.isNotEmpty == true
                          ? m.description!
                          : m.category.name,
                      style: AppTextStyles.authBody,
                    ),
                    Text(
                      formatDate(m.date),
                      style: AppTextStyles.authSubtitle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${formatCurrency(m.amount, currency)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      // A transfer is neither income nor expense (see
                      // TransactionEntry.isTransfer): neutral color instead of
                      // authIncome/authExpense.
                      color: m.isTransfer
                          ? AppColors.authTransfer
                          : m.isIncome
                              ? AppColors.authIncome
                              : AppColors.authExpense,
                    ),
                  ),
                  Text(
                    m.isIncome ? 'Ingreso' : m.category.name,
                    style: AppTextStyles.authSubtitle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
