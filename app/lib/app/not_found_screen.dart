import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/luma_logo.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

/// Pantalla para las URLs que no existen (ver `errorBuilder` en
/// router.dart).
///
/// Va por fuera del shell a propósito: sin header, sin drawer y sin bottom
/// nav. El botón manda a '/': si hay sesión abre el Dashboard, y si no, el
/// `redirect` del router lo manda a '/login'.
class NotFoundScreen extends StatelessWidget {
  /// Ruta que se intentó abrir. Solo informativa.
  final String? location;

  const NotFoundScreen({super.key, this.location});

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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LumaLogo(size: 56),
                      const SizedBox(height: 24),
                      const Text(
                        '404',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authAccent,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Página no encontrada',
                        style: AppTextStyles.authTitle.copyWith(fontSize: 26),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'La dirección que abriste no existe\n'
                        'o ya no está disponible.',
                        style: AppTextStyles.authSubtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () => context.go('/'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.authAccent,
                          foregroundColor: AppColors.authBackgroundBottom,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ir al inicio',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
