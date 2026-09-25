import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../view_models/app_lock_view_model.dart';

/// Pantalla de bloqueo ('/lock' — ver router.dart). Va por fuera del
/// shell, igual que LoginScreen y NotFoundScreen: sin header, sin bottom
/// nav. Solo se llega acá si `AppLockViewModel.isLocked` es `true`, lo que
/// a su vez solo pasa si el dispositivo soporta biometría Y el usuario la
/// activó en Preferencias (ver AppLockViewModel).
class LockScreen extends StatelessWidget {
  final AppLockViewModel viewModel;
  final AuthViewModel authViewModel;

  const LockScreen({
    super.key,
    required this.viewModel,
    required this.authViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final remainingAttempts =
            kAppLockMaxFailedAttempts - viewModel.failedAttempts;
        final hadFailedAttempt = viewModel.failedAttempts > 0;

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
                          const Icon(
                            Icons.fingerprint_rounded,
                            size: 64,
                            color: AppColors.authAccent,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'App bloqueada',
                            style: AppTextStyles.authTitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            viewModel.deviceLostSupport
                                ? 'Este dispositivo ya no tiene biometría ni '
                                    'PIN/patrón configurado. Configurá un '
                                    'método de desbloqueo en los ajustes del '
                                    'sistema, o cerrá sesión — desactivamos '
                                    'el bloqueo para que no vuelva a pasar.'
                                : hadFailedAttempt
                                    ? 'No pudimos confirmar tu identidad. '
                                        'Te quedan $remainingAttempts '
                                        '${remainingAttempts == 1 ? 'intento' : 'intentos'}.'
                                    : 'Confirmá tu identidad para continuar.',
                            style: AppTextStyles.authSubtitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          if (!viewModel.deviceLostSupport)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: viewModel.isAuthenticating
                                    ? null
                                    : viewModel.authenticate,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.authAccent,
                                  foregroundColor:
                                      AppColors.authBackgroundBottom,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: viewModel.isAuthenticating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              AppColors.authBackgroundBottom,
                                        ),
                                      )
                                    : const Text(
                                        'Desbloquear',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: authViewModel.signOut,
                            child: const Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: AppColors.authTextSecondary,
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
      },
    );
  }
}
