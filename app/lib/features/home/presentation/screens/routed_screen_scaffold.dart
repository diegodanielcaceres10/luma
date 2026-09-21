import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Scaffold de las pantallas que se abren como ruta propia (formularios,
/// listados, saldos iniciales, etc.): fondo con degradé y el contenido de
/// la pantalla. No dibuja AppBar ni botón "atrás": el header, el drawer y
/// el bottom nav los pone AppShellScreen por fuera, y cada pantalla trae
/// su propio título y su botón de volver (`context.goBack()`, ver
/// core/navigation/app_back.dart).
class RoutedScreenScaffold extends StatelessWidget {
  final Widget body;

  const RoutedScreenScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
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
