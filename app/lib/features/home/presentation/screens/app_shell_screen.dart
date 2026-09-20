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
        drawer: _AppDrawer(branchIndex: _branchIndex, onSelectBranch: _onNavTap),
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
  final ValueChanged<int> onSelectBranch;

  const _AppDrawer({required this.branchIndex, required this.onSelectBranch});

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
              isSelected: branchIndex == 0,
              onTap: () => onSelectBranch(0),
            ),
            // Cuentas, Categorías, Servicios y Facturas ya son rutas
            // propias — se abren empujando directo, sin pasar por
            // AppShellScreen. No se resaltan acá: son pantallas
            // transitorias que se empujan por encima de la rama actual,
            // no "la pestaña activa" en el sentido del bottom nav.
            _tile(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cuentas',
              isSelected: false,
              onTap: () {
                onSelectBranch(0);
                context.push('/accounts');
              },
            ),
            _tile(
              context,
              icon: Icons.sell_outlined,
              label: 'Categorías',
              isSelected: false,
              onTap: () {
                onSelectBranch(0);
                context.push('/categories');
              },
            ),
            _tile(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Servicios',
              isSelected: false,
              onTap: () {
                onSelectBranch(0);
                context.push('/services');
              },
            ),
            _tile(
              context,
              icon: Icons.request_page_outlined,
              label: 'Facturas',
              isSelected: false,
              onTap: () {
                onSelectBranch(0);
                context.push('/invoices');
              },
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
