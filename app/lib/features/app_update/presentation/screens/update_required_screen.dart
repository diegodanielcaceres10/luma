import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/luma_logo.dart';

/// Pantalla que bloquea toda la app cuando la versión instalada quedó por
/// debajo de la mínima requerida (ver Edge Function `check-app-version`).
///
/// Mismo layout que el login (logo + título centrados) pero sin la imagen
/// de fondo: acá no hay nada que hacer más que esperar a que un admin
/// habilite una nueva versión, así que tampoco hay botón.
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
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
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
                      style: AppTextStyles.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message ?? _defaultMessage,
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
