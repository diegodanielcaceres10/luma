import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../widgets/luma_header.dart';

/// Shortcuts shared between the bottom nav and the drawer: (icon, label,
/// route). These are the 4 fixed bottom nav entries — see router.dart.
const _navItems = [
  (Icons.home_rounded, 'Inicio', '/'),
  (Icons.trending_up_rounded, 'Movimientos', '/movements'),
  (Icons.bar_chart_rounded, 'Estadísticas', '/statistics'),
  (Icons.person_outline_rounded, 'Perfil', '/profile'),
];

/// Bottom nav index that corresponds to a route. Movements, Statistics and
/// Profile are highlighted by prefix; any other route (the Dashboard,
/// Accounts, Categories, Services, Invoices, forms, etc.) counts as "Home".
int _navIndexFor(String path) {
  for (var i = 1; i < _navItems.length; i++) {
    final base = _navItems[i].$3;
    if (path == base || path.startsWith('$base/')) return i;
  }
  return 0;
}

/// Shared scaffold (drawer, header, bottom nav) of a common `ShellRoute`:
/// there is ONE Navigator and ONE stack for the whole app. Bottom nav and
/// drawer navigate with `context.push`, so every screen that is opened gets
/// stacked and "back" (browser or device button) always returns to the
/// previous screen, in the same order they were visited — with no manual
/// "back" handling.
///
/// Tapping the destination you are already on does nothing, to avoid
/// stacking the same screen twice in a row.
class AppShellScreen extends StatelessWidget {
  /// The `ShellRoute` Navigator: the current screen and the stacked ones.
  final Widget child;

  const AppShellScreen({super.key, required this.child});

  Widget? _headerAction(int navIndex) {
    switch (navIndex) {
      case 0: // Home
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
          color: AppColors.authTextPrimary,
        );
      case 3: // Profile
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.settings_outlined),
          color: AppColors.authTextPrimary,
        );
      default: // Movements, Statistics
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final navIndex = _navIndexFor(uri.path);

    // Compared against the full location (with query params) so that tapping
    // "Invoices" while on '/invoices?filter=pending' does open the unfiltered
    // list.
    void navigateTo(String target) {
      if (uri.toString() == target) return;
      context.push(target);
    }

    return Scaffold(
      drawer: _AppDrawer(
        location: uri.path,
        onNavigate: navigateTo,
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
          bottom: false,
          child: Column(
            children: [
              LumaHeader(trailing: _headerAction(navIndex)),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: navIndex,
        onTap: (i) => navigateTo(_navItems[i].$3),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.authBackgroundBottom,
        border: Border(top: BorderSide(color: AppColors.authCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = i == currentIndex;
              final color =
                  isSelected ? AppColors.authAccent : AppColors.authTextFooter;

              return InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, color: color, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 16,
                        height: 2,
                        child: isSelected
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.authAccent,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  /// Current route (without query params).
  final String location;

  /// Navigates (with `push`) to the requested route — see [AppShellScreen].
  final ValueChanged<String> onNavigate;

  const _AppDrawer({
    required this.location,
    required this.onNavigate,
  });

  /// `true` if the current location is that base or one of its sub-routes
  /// (e.g. '/accounts/new' or '/accounts/abc/edit' count as "Accounts").
  bool _isActive(String base) =>
      location == base || location.startsWith('$base/');

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color =
        isSelected ? AppColors.authAccent : AppColors.authTextSecondary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.authCardFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = _navIndexFor(location);
    final isAccounts =
        _isActive('/accounts') || _isActive('/accounts-overview');
    final isCategories = _isActive('/categories');
    final isServices = _isActive('/services');
    final isInvoices = _isActive('/invoices');
    // "Home" is only highlighted when none of the other four routes is
    // active — otherwise "Home" stayed marked while navigating through
    // Accounts, Categories, etc.
    // Initial balance, new transaction and transfer do keep counting as
    // "Home".
    final isHome = navIndex == 0 &&
        !isAccounts &&
        !isCategories &&
        !isServices &&
        !isInvoices;

    return Drawer(
      backgroundColor: AppColors.authBackgroundBottom,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  LumaLogo(size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Luma',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.authCardBorder),
            const SizedBox(height: 8),
            // Home
            _tile(
              context,
              icon: _navItems[0].$1,
              label: _navItems[0].$2,
              isSelected: isHome,
              onTap: () => onNavigate(_navItems[0].$3),
            ),
            // Accounts, Categories, Services and Invoices: drawer-only destinations.
            // They are opened with `push` (via `onNavigate`) so they stack in the
            // single history and "back" returns to the screen they were opened from.
            _tile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cuentas',
              isSelected: isAccounts,
              onTap: () => onNavigate('/accounts'),
            ),
            _tile(
              context,
              icon: Icons.sell_outlined,
              label: 'Categorías',
              isSelected: isCategories,
              onTap: () => onNavigate('/categories'),
            ),
            _tile(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Servicios',
              isSelected: isServices,
              onTap: () => onNavigate('/services'),
            ),
            _tile(
              context,
              icon: Icons.request_page_outlined,
              label: 'Facturas',
              isSelected: isInvoices,
              onTap: () => onNavigate('/invoices'),
            ),
            // Movements, Statistics, Profile
            ...List.generate(_navItems.length - 1, (i) {
              final index = i + 1;
              final item = _navItems[index];
              return _tile(
                context,
                icon: item.$1,
                label: item.$2,
                isSelected: navIndex == index,
                onTap: () => onNavigate(item.$3),
              );
            }),
          ],
        ),
      ),
    );
  }
}
