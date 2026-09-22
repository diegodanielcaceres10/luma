import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../widgets/luma_header.dart';

/// Accesos compartidos entre el bottom nav y el drawer: (ícono, texto,
/// ruta). Son las 4 entradas fijas del bottom nav — ver router.dart.
const _navItems = [
  (Icons.home_rounded, 'Inicio', '/'),
  (Icons.trending_up_rounded, 'Movimientos', '/movements'),
  (Icons.bar_chart_rounded, 'Estadísticas', '/statistics'),
  (Icons.person_outline_rounded, 'Perfil', '/profile'),
];

/// Índice del bottom nav que corresponde a una ruta. Movimientos,
/// Estadísticas y Perfil se resaltan por prefijo; cualquier otra ruta
/// (el Dashboard, Cuentas, Categorías, Servicios, Facturas, formularios,
/// etc.) cuenta como "Inicio", igual que antes.
int _navIndexFor(String path) {
  for (var i = 1; i < _navItems.length; i++) {
    final base = _navItems[i].$3;
    if (path == base || path.startsWith('$base/')) return i;
  }
  return 0;
}

/// Scaffold compartido (drawer, header, bottom nav) de un `ShellRoute`
/// común: hay UN solo Navigator y UNA sola pila para toda la app. Bottom
/// nav y drawer navegan con `context.push`, así que cada pantalla que se
/// abre se apila y "atrás" (botón del navegador o del dispositivo)
/// vuelve siempre a la pantalla anterior, en el mismo orden en que se
/// visitaron — sin manejo de "atrás" a mano.
///
/// Tocar el destino en el que ya estás no hace nada, para no apilar la
/// misma pantalla dos veces seguidas.
class AppShellScreen extends StatelessWidget {
  /// El Navigator del `ShellRoute`: la pantalla actual y las apiladas.
  final Widget child;

  const AppShellScreen({super.key, required this.child});

  Widget? _headerAction(int navIndex) {
    switch (navIndex) {
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
    final uri = GoRouterState.of(context).uri;
    final navIndex = _navIndexFor(uri.path);

    // Se compara contra la ubicación completa (con query params) para que
    // tocar "Facturas" estando en '/invoices?filter=pending' sí abra el
    // listado sin filtrar.
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
  /// Ruta actual (sin query params).
  final String location;

  /// Navega (con `push`) a la ruta pedida — ver [AppShellScreen].
  final ValueChanged<String> onNavigate;

  const _AppDrawer({
    required this.location,
    required this.onNavigate,
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
    final navIndex = _navIndexFor(location);
    final isAccounts =
        _isActive('/accounts') || _isActive('/accounts-overview');
    final isCategories = _isActive('/categories');
    final isServices = _isActive('/services');
    final isInvoices = _isActive('/invoices');
    // "Inicio" solo se resalta cuando ninguna de las otras cuatro rutas
    // es la que está activa — si no, se quedaba marcado "Inicio" mientras
    // se navegaba por Cuentas, Categorías, etc.
    // Saldo inicial, nueva transacción y transferencia sí siguen contando
    // como "Inicio", tal como antes.
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
            // Inicio
            _tile(
              context,
              icon: _navItems[0].$1,
              label: _navItems[0].$2,
              isSelected: isHome,
              onTap: () => onNavigate(_navItems[0].$3),
            ),
            // Cuentas, Categorías, Servicios y Facturas: destinos propios
            // del drawer. Se abren con `push` (vía `onNavigate`) para que
            // se apilen en el historial único y "atrás" vuelva a la
            // pantalla desde la que se abrieron.
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
            // Movimientos, Estadísticas, Perfil
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
