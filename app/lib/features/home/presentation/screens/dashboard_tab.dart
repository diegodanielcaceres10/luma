import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../monthly_balances/presentation/view_models/monthly_balance_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../../../transactions/data/models/transaction_entry.dart';
import '../../../transactions/presentation/view_models/transaction_view_model.dart';

/// Contenido de la pestaña "Inicio". No tiene Scaffold propio — se muestra
/// dentro del Scaffold de AppShellScreen, que pone el header y el
/// bottomNavigationBar.
///
/// Mientras no lleguen todos los datos iniciales muestra solo un spinner.
/// Después, según las cuentas activas, muestra el card para crear la primera
/// cuenta o el resto del contenido.
class DashboardTab extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;
  final TransactionViewModel transactionViewModel;
  final CategoryViewModel categoryViewModel;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final InvoiceViewModel invoiceViewModel;
  final ServiceViewModel serviceViewModel;
  final VoidCallback? onSeeAllMovements;
  final VoidCallback onOpenMonthlyBalances;
  final ValueChanged<String> onOpenAddTransaction;
  final VoidCallback onGoToAccounts;
  final VoidCallback onManageAccounts;
  final VoidCallback onGoToInvoices;
  final VoidCallback onGoToTransfers;

  const DashboardTab({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
    required this.transactionViewModel,
    required this.categoryViewModel,
    required this.monthlyBalanceViewModel,
    required this.invoiceViewModel,
    required this.serviceViewModel,
    required this.onOpenMonthlyBalances,
    required this.onOpenAddTransaction,
    required this.onGoToAccounts,
    required this.onManageAccounts,
    required this.onGoToInvoices,
    required this.onGoToTransfers,
    this.onSeeAllMovements,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  // Se vuelve true cuando termina la primera carga y ya no se revierte: los
  // refrescos posteriores (p. ej. tras crear un movimiento) no deben tapar
  // el dashboard con el spinner, para eso quedan los spinners de cada
  // sección.
  bool _initialLoadDone = false;

  // Para leer dónde quedó el botón flotante y dibujar el "×" del overlay
  // exactamente encima.
  final GlobalKey _fabKey = GlobalKey();

  /// `true` cuando todos los datos que usa el dashboard terminaron de
  /// cargar. Las cuentas se validan con `hasLoaded` porque antes de que
  /// arranque la carga `isLoading` todavía es false y se vería el card de
  /// "sin cuentas" por un instante.
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

        // Si fallan las cuentas nunca llega `hasLoaded`; sin este caso el
        // spinner quedaría infinito.
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

  /// Abre el menú de acciones rápidas: un overlay sobre toda la pantalla
  /// (root navigator, para cubrir también el header y el bottom nav del
  /// shell) con el fondo blureado y las 4 opciones.
  void _openQuickActions() {
    final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final fabRect = box.localToGlobal(Offset.zero) & box.size;
    final pendingInvoicesCount = widget.invoiceViewModel.pendingCount;

    final options = [
      _QuickActionOption(
        icon: Icons.arrow_downward_rounded,
        iconColor: AppColors.authIncome,
        title: 'Agregar ingreso',
        subtitle: 'Sumá dinero a tu cuenta',
        onTap: () => widget.onOpenAddTransaction('income'),
      ),
      _QuickActionOption(
        icon: Icons.arrow_upward_rounded,
        iconColor: AppColors.authExpense,
        title: 'Agregar gasto',
        subtitle: 'Registrá un nuevo gasto',
        onTap: () => widget.onOpenAddTransaction('expense'),
      ),
      _QuickActionOption(
        icon: Icons.request_page_outlined,
        iconColor: AppColors.authAccent,
        title: 'Facturas por pagar',
        subtitle: pendingInvoicesCount > 0
            ? '$pendingInvoicesCount pendiente'
                '${pendingInvoicesCount == 1 ? '' : 's'} este mes'
            : 'Revisá el estado de tus facturas',
        onTap: widget.onGoToInvoices,
      ),
      _QuickActionOption(
        icon: Icons.swap_horiz_rounded,
        iconColor: AppColors.authAccent,
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
      // El overlay anima su propio blur, opciones y botón con `animation`.
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
            // Padding inferior extra para que el botón flotante no tape el
            // último movimiento.
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
                pendingAccountsCount: pendingAccounts.length,
                onCompletePendingBalances: pendingAccounts.isEmpty
                    ? null
                    : widget.onOpenMonthlyBalances,
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

/// Spinner centrado mientras llegan los datos iniciales del dashboard.
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

/// Se muestra si no se pudieron cargar las cuentas, para no dejar el spinner
/// girando para siempre ni mostrar el card de "sin cuentas" por error.
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

  /// Ingresos - gastos del mes en curso, más los ajustes sin declarar de
  /// ese mismo mes (ver
  /// [TransactionViewModel.netResultWithUncontrolled]).
  final double netResult;
  final bool isLoadingNetResult;
  final int pendingAccountsCount;
  final VoidCallback? onCompletePendingBalances;
  final VoidCallback onManageAccounts;

  /// Cuentas activas, para el detalle que se despliega en el card.
  final List<Account> accounts;
  final double pendingInvoicesTotal;

  /// Facturas pendientes (ni pagadas ni canceladas) del mes en curso.
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
    this.pendingAccountsCount = 0,
    this.onCompletePendingBalances,
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
            if (pendingAccountsCount > 0) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              _PendingBalancesAlert(
                count: pendingAccountsCount,
                onTap: onCompletePendingBalances,
              ),
            ],
            const SizedBox(height: 8),
            _BalanceAccountsExpander(
              accounts: accounts,
              currency: currency,
              onManageAccounts: onManageAccounts,
            ),
          ],
        ),
      ),
    );
  }
}

/// Parte desplegable del [_BalanceCard]: un chevron al pie del card que, al
/// tocarlo, muestra el saldo de cada cuenta y el acceso a la configuración
/// de cuentas. Arranca colapsado y su estado no se conserva entre sesiones.
class _BalanceAccountsExpander extends StatefulWidget {
  final List<Account> accounts;
  final String currency;
  final VoidCallback onManageAccounts;

  const _BalanceAccountsExpander({
    required this.accounts,
    required this.currency,
    required this.onManageAccounts,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
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
                  formatCurrency(account.balance, widget.currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PendingBalancesAlert extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _PendingBalancesAlert({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = count == 1
        ? 'Falta cargar el saldo inicial de 1 cuenta este mes'
        : 'Faltan cargar los saldos iniciales de $count cuentas este mes';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
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
          const Text(
            'Completar',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFFBBF24), size: 16),
        ],
      ),
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

/// Una opción del menú de acciones rápidas.
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

/// Botón flotante circular verde con un "+". El overlay de acciones rápidas
/// lo redibuja en la misma posición con [rotation] para convertirlo en "×".
class _AddFab extends StatelessWidget {
  static const double size = 56;

  final VoidCallback onPressed;

  /// Giro del ícono, en radianes.
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

/// Menú de acciones rápidas: fondo blureado sobre toda la pantalla, las
/// opciones apiladas sobre el botón y el botón en su lugar, ya como "×".
/// Tocar el fondo, el botón o una opción lo cierra.
class _QuickActionsOverlay extends StatelessWidget {
  final Animation<double> animation;

  /// Posición del botón flotante en coordenadas de pantalla.
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

  /// Entrada escalonada: la opción más cercana al botón aparece primero.
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

    final dateFormat = DateFormat('d MMM yyyy', 'es');

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
                      dateFormat.format(m.date),
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
                      // Una transferencia no es ni ingreso ni gasto (ver
                      // TransactionEntry.isTransfer): color neutro en vez
                      // de authIncome/authExpense.
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
