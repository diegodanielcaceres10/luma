import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/layout/luma_logo.dart';
import '../../../../core/widgets/layout/max_width_frame.dart';
import '../widgets/luma_header.dart';

/// Breakpoints for responsive layout.
const double kTabletBreakpoint = 600;
const double kDesktopBreakpoint = 1024;
const double kWideDesktopBreakpoint = 1440;

/// Maximum width for the main content area on desktop viewports.
const double kAppMaxDesktopContentWidth = 1200;

/// Shortcuts shared between the bottom nav and the drawer: (icon, label,
/// route). These are the 4 fixed bottom nav entries — see router.dart.
const _navItems = [
  (Icons.home_rounded, 'Inicio', '/'),
  (Icons.trending_up_rounded, 'Movimientos', '/movements'),
  (Icons.bar_chart_rounded, 'Estadísticas', '/statistics'),
  (Icons.person_outline_rounded, 'Perfil', '/profile'),
];

/// Green gradient behind the shell; also fills the sides on wide screens.
const _shellBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.authBackgroundTop,
      AppColors.authBackgroundBottom,
    ],
  ),
);

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

bool _isRouteActive(String location, String base) =>
    location == base || location.startsWith('$base/');

/// Width of the persistent sidebar (tablet and desktop layouts only).
double _sidebarWidthFor({
  required bool isCompact,
  required bool isWideDesktop,
}) =>
    isCompact ? 72.0 : (isWideDesktop ? 260.0 : 240.0);

class _NavDestination {
  final IconData icon;
  final String label;
  final String route;
  final bool Function(String location, int navIndex) isSelected;

  const _NavDestination({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
  });
}

final _allNavItems = [
  _NavDestination(
    icon: Icons.home_rounded,
    label: 'Inicio',
    route: '/',
    isSelected: (loc, navIndex) =>
        navIndex == 0 &&
        !_isRouteActive(loc, '/accounts') &&
        !_isRouteActive(loc, '/accounts-overview') &&
        !_isRouteActive(loc, '/categories') &&
        !_isRouteActive(loc, '/services') &&
        !_isRouteActive(loc, '/invoices'),
  ),
  _NavDestination(
    icon: Icons.account_balance_wallet_outlined,
    label: 'Cuentas',
    route: '/accounts',
    isSelected: (loc, _) =>
        _isRouteActive(loc, '/accounts') ||
        _isRouteActive(loc, '/accounts-overview'),
  ),
  _NavDestination(
    icon: Icons.sell_outlined,
    label: 'Categorías',
    route: '/categories',
    isSelected: (loc, _) => _isRouteActive(loc, '/categories'),
  ),
  _NavDestination(
    icon: Icons.receipt_long_outlined,
    label: 'Servicios',
    route: '/services',
    isSelected: (loc, _) => _isRouteActive(loc, '/services'),
  ),
  _NavDestination(
    icon: Icons.request_page_outlined,
    label: 'Facturas',
    route: '/invoices',
    isSelected: (loc, _) => _isRouteActive(loc, '/invoices'),
  ),
  _NavDestination(
    icon: Icons.trending_up_rounded,
    label: 'Movimientos',
    route: '/movements',
    isSelected: (_, navIndex) => navIndex == 1,
  ),
  _NavDestination(
    icon: Icons.bar_chart_rounded,
    label: 'Estadísticas',
    route: '/statistics',
    isSelected: (_, navIndex) => navIndex == 2,
  ),
  _NavDestination(
    icon: Icons.person_outline_rounded,
    label: 'Perfil',
    route: '/profile',
    isSelected: (_, navIndex) => navIndex == 3,
  ),
];

/// Shared scaffold (drawer, header, bottom nav or sidebar) of a common `ShellRoute`:
/// there is ONE Navigator and ONE stack for the whole app. Bottom nav,
/// drawer and sidebar navigate with `context.push`, so every screen that is opened gets
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

  Widget _buildContentHeader({
    required bool isMobile,
    required Widget? trailing,
  }) {
    if (isMobile) {
      return LumaHeader(trailing: trailing);
    }
    if (trailing == null) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: trailing,
      ),
    );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < kTabletBreakpoint;
        final isTablet =
            width >= kTabletBreakpoint && width < kDesktopBreakpoint;
        final isWideDesktop = width >= kWideDesktopBreakpoint;

        if (isMobile) {
          // Mobile view (< 600 px): exactly the original layout with drawer,
          // header and bottom navigation bar capped at MaxWidthFrame.
          return MaxWidthFrame(
            sideDecoration: _shellBackground,
            child: Scaffold(
              drawer: _AppDrawer(
                location: uri.path,
                navIndex: navIndex,
                onNavigate: navigateTo,
              ),
              body: DecoratedBox(
                decoration: _shellBackground,
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
            ),
          );
        }

        // Tablet & Desktop Web view (>= 600 px): persistent sidebar on the left,
        // main content area on the right.
        return Scaffold(
          body: DecoratedBox(
            decoration: _shellBackground,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  _AppSidebar(
                    location: uri.path,
                    navIndex: navIndex,
                    isCompact: isTablet,
                    isWideDesktop: isWideDesktop,
                    onNavigate: navigateTo,
                  ),
                  Expanded(
                    child: _DialogsCenteredOnContent(
                      sidebarWidth: _sidebarWidthFor(
                        isCompact: isTablet,
                        isWideDesktop: isWideDesktop,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: kAppMaxDesktopContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildContentHeader(
                                isMobile: false,
                                trailing: _headerAction(navIndex),
                              ),
                              Expanded(child: child),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dialogs open on the root navigator and center on the whole window, which
/// leaves them off-center next to the content when a sidebar is showing.
/// `showDialog` captures the theme of the context it is called from, so
/// reserving the sidebar's width in the dialog insets here centers every
/// dialog opened from the content area on the content itself.
class _DialogsCenteredOnContent extends StatelessWidget {
  final double sidebarWidth;
  final Widget child;

  const _DialogsCenteredOnContent({
    required this.sidebarWidth,
    required this.child,
  });

  // Material's default dialog insets, plus the sidebar on the left.
  static const _horizontal = 40.0;
  static const _vertical = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        dialogTheme: theme.dialogTheme.copyWith(
          insetPadding: EdgeInsets.fromLTRB(
            sidebarWidth + _horizontal,
            _vertical,
            _horizontal,
            _vertical,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _AppSidebar extends StatelessWidget {
  final String location;
  final int navIndex;
  final bool isCompact;
  final bool isWideDesktop;
  final ValueChanged<String> onNavigate;

  const _AppSidebar({
    required this.location,
    required this.navIndex,
    required this.isCompact,
    required this.isWideDesktop,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = _sidebarWidthFor(
      isCompact: isCompact,
      isWideDesktop: isWideDesktop,
    );

    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.navBackgroundTop,
            AppColors.navBackgroundBottom,
          ],
        ),
        border: Border(
          right: BorderSide(color: AppColors.authCardBorder),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: isCompact
                  ? const EdgeInsets.symmetric(vertical: 20)
                  : const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: isCompact
                  ? const Center(child: LumaLogo(size: 28))
                  : const Row(
                      children: [
                        LumaLogo(size: 28),
                        SizedBox(width: 10),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _allNavItems.map((item) {
                    final isSelected = item.isSelected(location, navIndex);
                    return isCompact
                        ? _compactTile(
                            icon: item.icon,
                            label: item.label,
                            isSelected: isSelected,
                            onTap: () => onNavigate(item.route),
                          )
                        : _expandedTile(
                            icon: item.icon,
                            label: item.label,
                            isSelected: isSelected,
                            onTap: () => onNavigate(item.route),
                          );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandedTile({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color =
        isSelected ? AppColors.authAccent : AppColors.authTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.authCardFill : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.authCardFill,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.authAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactTile({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color =
        isSelected ? AppColors.authAccent : AppColors.authTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          color: isSelected ? AppColors.authCardFill : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: AppColors.authCardFill,
            child: SizedBox(
              height: 44,
              child: Center(
                child: Icon(icon, color: color, size: 22),
              ),
            ),
          ),
        ),
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
        color: AppColors.navBackgroundBottom,
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

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$1, color: color, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          width: 16,
                          height: 2,
                          child: isSelected
                              ? const DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.authAccent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(2)),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
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
  final int navIndex;

  /// Navigates (with `push`) to the requested route — see [AppShellScreen].
  final ValueChanged<String> onNavigate;

  const _AppDrawer({
    required this.location,
    required this.navIndex,
    required this.onNavigate,
  });

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
    return Drawer(
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.navBackgroundTop,
              AppColors.navBackgroundBottom,
            ],
          ),
        ),
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
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _allNavItems.map((item) {
                    return _tile(
                      context,
                      icon: item.icon,
                      label: item.label,
                      isSelected: item.isSelected(location, navIndex),
                      onTap: () => onNavigate(item.route),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
