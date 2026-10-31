import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/layout/luma_logo.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/text_action_button.dart';
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
          body: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.authBackgroundTop,
                        AppColors.authBackgroundBottom,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -80,
                left: 0,
                right: 0,
                height: 360,
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.authAccent.withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 36,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.authCardFill,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.authCardBorder
                                    .withValues(alpha: 0.35),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LumaLogo(size: 52),
                                const SizedBox(height: 28),
                                _BiometricBadge(
                                  isAuthenticating: viewModel.isAuthenticating,
                                  hadFailedAttempt: hadFailedAttempt,
                                  deviceLostSupport:
                                      viewModel.deviceLostSupport,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'App bloqueada',
                                  style: AppTextStyles.authTitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                _buildStatusMessage(
                                  viewModel: viewModel,
                                  hadFailedAttempt: hadFailedAttempt,
                                  remainingAttempts: remainingAttempts,
                                ),
                                const SizedBox(height: 32),
                                if (!viewModel.deviceLostSupport) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.authAccent
                                              .withValues(alpha: 0.32),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: PrimaryButton(
                                        label: 'Desbloquear',
                                        icon: Icons.lock_open_rounded,
                                        labelStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                        borderRadius: 14,
                                        isLoading: viewModel.isAuthenticating,
                                        onPressed: viewModel.isAuthenticating
                                            ? null
                                            : viewModel.authenticate,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage({
    required AppLockViewModel viewModel,
    required bool hadFailedAttempt,
    required int remainingAttempts,
  }) {
    final message = viewModel.deviceLostSupport
        ? 'Este dispositivo ya no tiene biometría ni '
            'PIN/patrón configurado. Configurá un '
            'método de desbloqueo en los ajustes del '
            'sistema, o cerrá sesión — desactivamos '
            'el bloqueo para que no vuelva a pasar.'
        : hadFailedAttempt
            ? 'No pudimos confirmar tu identidad. '
                'Te quedan $remainingAttempts '
                '${remainingAttempts == 1 ? 'intento' : 'intentos'}.'
            : 'Confirmá tu identidad para continuar.';

    if (viewModel.deviceLostSupport) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFFDE68A),
            fontSize: 13,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (hadFailedAttempt) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.authExpense.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.authExpense.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppColors.authExpense,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFFFB4A9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      message,
      style: AppTextStyles.authSubtitle.copyWith(
        fontSize: 14,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _BiometricBadge extends StatelessWidget {
  final bool isAuthenticating;
  final bool hadFailedAttempt;
  final bool deviceLostSupport;

  const _BiometricBadge({
    required this.isAuthenticating,
    required this.hadFailedAttempt,
    required this.deviceLostSupport,
  });

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = deviceLostSupport
        ? const Color(0xFFFBBF24)
        : hadFailedAttempt
            ? AppColors.authExpense
            : AppColors.authAccent;

    final IconData icon = deviceLostSupport
        ? Icons.lock_person_outlined
        : Icons.fingerprint_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: isAuthenticating ? 1.05 : 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  badgeColor.withValues(alpha: 0.22),
                  badgeColor.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 46,
                color: badgeColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
