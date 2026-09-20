import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../widgets/luma_header.dart';

/// Accesos compartidos entre el bottom nav y el drawer — una entrada por
/// rama real de `StatefulShellRoute.indexedStack` (ver router.dart).
const _navItems = [
  (Icons.home_rounded, 'Inicio'),
  (Icons.trending_up_rounded, 'Movimientos'),
  (Icons.bar_chart_rounded, 'Estadísticas'),
  (Icons.person_outline_rounded, 'Perfil'),
];

/// MIGRACIÓN A RUTAS COMPLETA: el Scaffold compartido (drawer, header,
/// bottom nav) de las 4 ramas reales del bottom nav. Todo lo que antes
/// era "pestaña virtual" (Cuentas, Categorías, Servicios, Facturas, saldo
/// inicial, nueva transacción, transferencia) ya es ruta propia con su
/// propio AppBar y back nativo del Navigator — por eso esta pantalla ya
/// no necesita saber nada de eso: el único "atrás" que le queda por
/// resolver es entre las 4 ramas del bottom nav mismas.
class AppShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final AuthViewModel authViewModel;

  const AppShellScreen({
    super.key,
    required this.navigationShell,
    required this.authViewModel,
  });

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int get _branchIndex => widget.navigationShell.currentIndex;

  /// Tocar la rama ya activa vuelve a su raíz — ej. tocar "Inicio" desde
  /// adentro de "Nueva cuenta" (empujada por encima) vuelve al Dashboard,
  /// mismo criterio de siempre para el bottom nav.
  void _onNavTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == _branchIndex,
    );
  }

  Widget? _headerAction() {
    switch (_branchIndex) {
      case 0: // Inicio
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
          color: AppColors.authTextPrimary,
        );
      case 3: // Perfil
        return const IconButton(
          onPressed: null,
          icon: Icon(Icons.settings_outlined),
          color: AppColors.authTextPrimary,
        );
      default: // Movimientos, Estadísticas
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo dejamos que el sistema haga "pop" real (cerrar la app en
    // Android, navegar atrás en el browser) en la rama "Inicio" — desde
    // cualquier otra rama, "atrás" vuelve primero a "Inicio". Cada
    // pantalla empujada por encima de una rama (formularios, listados)
    // ya resuelve su propio "atrás" con su Navigator nativo, sin pasar
    // por acá.
    return PopScope(
      canPop: _branchIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.navigationShell.goBranch(0, initialLocation: true);
      },
      child: Scaffold(
        drawer: _AppDrawer(
          branchIndex: _branchIndex,
          location: GoRouterState.of(context).uri.path,
          onSelectBranch: _onNavTap,
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
                LumaHeader(trailing: _headerAction()),
                // navigationShell ya es el IndexedStack de las 4 ramas —
                // mantiene vivo el estado de cada una (scroll, filtros,
                // formularios a medio llenar) al cambiar de pestaña.
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _branchIndex,
          onTap: _onNavTap,
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
  final int branchIndex;
  final String location;
  final ValueChanged<int> onSelectBranch;

  const _AppDrawer({
    required this.branchIndex,
    required this.location,
    required this.onSelectBranch,
  });

  /// `true` si la ubicación actual es esa base o una sub-ruta suya
  /// (ej. '/accounts/new' o '/accounts/abc/edit' cuentan como "Cuentas").
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
    final isAccounts =
        _isActive('/accounts') || _isActive('/accounts-overview');
    final isCategories = _isActive('/categories');
    final isServices = _isActive('/services');
    final isInvoices = _isActive('/invoices');
    // "Inicio" solo se resalta cuando ninguna de las otras cuatro rutas
    // (todas anidadas bajo la misma rama) es la que está activa — si no,
    // se quedaba marcado "Inicio" mientras se navegaba por Cuentas,
    // Categorías, etc. Saldo inicial, nueva transacción y transferencia
    // sí siguen contando como "Inicio", tal como antes.
    final isHome = branchIndex == 0 &&
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
            // Inicio
            _tile(
              context,
              icon: _navItems[0].$1,
              label: _navItems[0].$2,
              isSelected: isHome,
              onTap: () => onSelectBranch(0),
            ),
            // Cuentas, Categorías, Servicios y Facturas ya son rutas
            // propias — viven anidadas bajo la rama "Inicio" para que el
            // bottom nav siga visible, pero se navega con `context.go()`
            // (no `push`) para que sea un único evento de ruteo atómico:
            // reemplaza toda la configuración por la ruta pedida (URL
            // específica y predecible siempre, venga de donde venga) y de
            // paso descarta cualquier pantalla que hubiera empujada por
            // encima de una visita anterior. Mezclar un `goBranch` previo
            // con un `push` aparte (como se hacía antes) son dos eventos
            // de ruteo separados y es lo que dejaba la URL sin
            // actualizarse.
            _tile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cuentas',
              isSelected: isAccounts,
              onTap: () => context.go('/accounts'),
            ),
            _tile(
              context,
              icon: Icons.sell_outlined,
              label: 'Categorías',
              isSelected: isCategories,
              onTap: () => context.go('/categories'),
            ),
            _tile(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Servicios',
              isSelected: isServices,
              onTap: () => context.go('/services'),
            ),
            _tile(
              context,
              icon: Icons.request_page_outlined,
              label: 'Facturas',
              isSelected: isInvoices,
              onTap: () => context.go('/invoices'),
            ),
            // Movimientos, Estadísticas, Perfil
            ...List.generate(_navItems.length - 1, (i) {
              final index = i + 1;
              final item = _navItems[index];
              return _tile(
                context,
                icon: item.$1,
                label: item.$2,
                isSelected: branchIndex == index,
                onTap: () => onSelectBranch(index),
              );
            }),
          ],
        ),
      ),
    );
  }
}
