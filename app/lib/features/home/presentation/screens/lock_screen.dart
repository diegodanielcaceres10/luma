import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/text_action_button.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../view_models/app_lock_view_model.dart';

/// Lock screen. Not a route: AppLockGate (see app.dart) shows it on top of
/// the whole app, so the screen the user was on stays untouched below. It is
/// only shown when `AppLockViewModel.isLocked` is `true`, which in turn only
/// happens if the device supports biometrics AND the user enabled it in
/// Preferences (see AppLockViewModel).
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
                              child: PrimaryButton(
                                label: 'Desbloquear',
                                labelStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                borderRadius: 14,
                                isLoading: viewModel.isAuthenticating,
                                onPressed: viewModel.isAuthenticating
                                    ? null
                                    : viewModel.authenticate,
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextActionButton(
                            label: 'Cerrar sesión',
                            fontWeight: FontWeight.w600,
                            onPressed: authViewModel.signOut,
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
