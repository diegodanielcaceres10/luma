import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../widgets/luma_header.dart';
import 'home_shell.dart';

/// Accesos compartidos entre el bottom nav y el drawer — una entrada por
/// rama real de `StatefulShellRoute.indexedStack` (ver router.dart).
const _navItems = [
  (Icons.home_rounded, 'Inicio'),
  (Icons.trending_up_rounded, 'Movimientos'),
  (Icons.bar_chart_rounded, 'Estadísticas'),
  (Icons.person_outline_rounded, 'Perfil'),
];

/// FASE 2/3 de la migración a rutas: el Scaffold compartido (drawer,
/// header, bottom nav) de las 4 ramas reales del bottom nav. Cuentas,
/// Categorías, Servicios y Facturas ya son rutas propias con su propio
/// AppBar (ver RoutedScreenScaffold) — por eso el drawer las abre con
/// `context.push` directo, sin pasar por acá.
///
/// "Inicio" (rama 0) todavía aloja, sin tocar su lógica, el Dashboard y
/// los 3 formularios que solo se abren desde ahí (agregar saldo inicial,
/// nueva transacción, transferencia) — ver [HomeBranchScreen]. Por eso
/// esta pantalla necesita [homeBranchKey]/[homeBranchRevision]: para
/// saber si puede dejar que el sistema haga "pop" real (solo en el
/// Dashboard) o si hay que resolver el "atrás" adentro de
/// HomeBranchScreen primero.
class AppShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final GlobalKey<HomeBranchScreenState> homeBranchKey;
  final Listenable homeBranchRevision;
  final AuthViewModel authViewModel;

  const AppShellScreen({
    super.key,
    required this.navigationShell,
    required this.homeBranchKey,
    required this.homeBranchRevision,
    required this.authViewModel,
  });

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int get _branchIndex => widget.navigationShell.currentIndex;
  HomeBranchScreenState? get _homeBranch => widget.homeBranchKey.currentState;

  @override
  void initState() {
    super.initState();
    // HomeBranchScreen (rama "Inicio") avisa por acá cada vez que cambia
    // su índice interno — hace falta reconstruirse para que el botón
    // atrás sepa si puede cerrar la app o no.
    widget.homeBranchRevision.addListener(_onHomeBranchChanged);
  }

  @override
  void dispose() {
    widget.homeBranchRevision.removeListener(_onHomeBranchChanged);
    super.dispose();
  }

  void _onHomeBranchChanged() => setState(() {});

  /// "Inicio" siempre vuelve al Dashboard, sin importar en qué formulario
  /// interno haya quedado — mismo criterio que tenía `_onTabTap(0)` en el
  /// HomeShell viejo.
  void _onNavTap(int index) {
    widget.navigationShell.goBranch(index);
    if (index == 0) _homeBranch?.goToDashboard();
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
    // Android, navegar atrás en el browser) cuando estamos en el
    // Dashboard de "Inicio". En cualquier otro caso lo interceptamos:
    // primero volvemos a la rama "Inicio", y si ya estábamos ahí,
    // resolvemos el "atrás" lógico adentro de HomeBranchScreen (mismo
    // criterio que tenía el HomeShell viejo). Cuentas/Categorías/
    // Servicios/Facturas ya no pasan por acá: al ser rutas propias, su
    // botón atrás lo maneja el Navigator solo.
    final canPopReally = _branchIndex == 0 && (_homeBranch?.isDashboard ?? true);

    return PopScope(
      canPop: canPopReally,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_branchIndex != 0) {
          widget.navigationShell.goBranch(0);
          _homeBranch?.goToDashboard();
        } else {
          _homeBranch?.handleBackPress();
        }
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
              onTap: () => context.push('/accounts'),
            ),
            _tile(
              context,
              icon: Icons.sell_outlined,
              label: 'Categorías',
              isSelected: false,
              onTap: () => context.push('/categories'),
            ),
            _tile(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Servicios',
              isSelected: false,
              onTap: () => context.push('/services'),
            ),
            _tile(
              context,
              icon: Icons.request_page_outlined,
              label: 'Facturas',
              isSelected: false,
              onTap: () => context.push('/invoices'),
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
