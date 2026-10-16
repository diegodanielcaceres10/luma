import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../accounts/presentation/view_models/monthly_balance_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';
import '../widgets/dashboard/balance_card.dart';
import '../widgets/dashboard/dashboard_headers.dart';
import '../widgets/dashboard/dashboard_status_views.dart';
import '../widgets/dashboard/quick_actions.dart';
import '../widgets/dashboard/recent_movements.dart';

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
          child = DashboardLoadErrorView(
            key: const ValueKey('dashboard-error'),
            onRetry: _retryLoad,
          );
        } else if (!_initialLoadDone) {
          child = const DashboardLoading(key: ValueKey('dashboard-loading'));
        } else {
          final activeAccounts = accountViewModel.activeAccounts;
          child = activeAccounts.isEmpty
              ? _buildNoAccounts()
              : _buildContent(activeAccounts);
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: child,
        );
      },
    );
  }

  // No active accounts — guide the user to create one.
  Widget _buildNoAccounts() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return ListView(
          key: const ValueKey('dashboard-no-accounts'),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 28 : 20,
            16,
            isDesktop ? 28 : 20,
            36,
          ),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardGreetingRow(
                      initials: widget.authViewModel.initials,
                      firstName:
                          widget.authViewModel.displayName.split(' ').first,
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: DashboardNoAccountsCard(
                          onGoToAccounts: widget.onGoToAccounts,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
      QuickActionOption(
        icon: Icons.arrow_upward_rounded,
        iconColor: AppColors.authExpense,
        title: 'Agregar gasto',
        subtitle: 'Registrá un nuevo gasto',
        onTap: () => widget.onOpenAddTransaction('expense'),
      ),
      QuickActionOption(
        icon: Icons.arrow_downward_rounded,
        iconColor: AppColors.authIncome,
        title: 'Agregar ingreso',
        subtitle: 'Sumá dinero a tu cuenta',
        onTap: () => widget.onOpenAddTransaction('income'),
      ),
      QuickActionOption(
        icon: Icons.request_page_outlined,
        iconColor: AppColors.authInvoice,
        title: 'Facturas por pagar',
        subtitle: pendingInvoicesCount > 0
            ? '$pendingInvoicesCount pendiente'
                '${pendingInvoicesCount == 1 ? '' : 's'} este mes'
            : 'Revisá el estado de tus facturas',
        onTap: widget.onGoToInvoices,
      ),
      QuickActionOption(
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
      pageBuilder: (dialogContext, animation, _) =>
          DashboardQuickActionsOverlay(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumn = constraints.maxWidth >= 768;

              final greetingWidget = DashboardGreetingRow(
                initials: widget.authViewModel.initials,
                firstName: widget.authViewModel.displayName.split(' ').first,
              );

              final balanceCardWidget = DashboardBalanceCard(
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
              );

              final movementsHeaderWidget = DashboardSectionHeader(
                title: 'Últimos movimientos',
                onSeeAll: widget.onSeeAllMovements,
              );

              final movementsListWidget = DashboardRecentMovements(
                isLoading: transactionViewModel.isLoading,
                movements: transactionViewModel.recentMovements,
                currency: accountViewModel.primaryCurrency,
              );

              if (isTwoColumn) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 96),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          greetingWidget,
                          const SizedBox(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: balanceCardWidget,
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    movementsHeaderWidget,
                                    const SizedBox(height: 12),
                                    movementsListWidget,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Single-column layout: mobile & narrow viewports (< 768 px)
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                children: [
                  greetingWidget,
                  const SizedBox(height: 22),
                  balanceCardWidget,
                  const SizedBox(height: 28),
                  movementsHeaderWidget,
                  const SizedBox(height: 12),
                  movementsListWidget,
                ],
              );
            },
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: DashboardAddFab(key: _fabKey, onPressed: _openQuickActions),
        ),
      ],
    );
  }
}
