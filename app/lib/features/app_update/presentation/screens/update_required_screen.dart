import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_system_ui.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/luma_logo.dart';

/// Pantalla que bloquea toda la app cuando la versión instalada quedó por
/// debajo de la mínima requerida (ver Edge Function `check-app-version`).
///
/// Mismo fondo (gradiente oscuro de marca) que usa el resto de la app en
/// [AppShellScreen] y el login, pero sin ilustración ni botón: acá no hay
/// nada que hacer más que esperar a que un admin habilite una nueva
/// versión.
class UpdateRequiredScreen extends StatelessWidget {
  final String? message;

  const UpdateRequiredScreen({super.key, this.message});

  static const _defaultMessage =
      'Esta versión de la app ya no está disponible.\n'
      'Comunicate con el administrador para conseguir la versión '
      'actualizada.';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: appStatusBarStyle,
        child: Scaffold(
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LumaLogo(size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Luma',
                          style: AppTextStyles.authTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          message ?? _defaultMessage,
                          style: AppTextStyles.authSubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
