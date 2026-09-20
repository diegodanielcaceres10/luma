import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// FASE 3 de la migración a rutas: Scaffold para pantallas que ya son
/// rutas propias (empujadas con `context.push`, dentro de la rama
/// "Inicio" del bottom nav — por eso el bottom nav sigue visible, es
/// AppShellScreen quien lo pone por fuera de esto). A diferencia del
/// header compartido que todavía usa HomeBranchScreen para lo que falta
/// migrar, acá cada pantalla tiene su propio AppBar con botón atrás
/// nativo del Navigator — no hace falta ningún PopScope a mano.
class RoutedScreenScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const RoutedScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.authBackgroundBottom,
        foregroundColor: AppColors.authTextPrimary,
        elevation: 0,
        actions: actions,
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
        child: body,
      ),
    );
  }
}
