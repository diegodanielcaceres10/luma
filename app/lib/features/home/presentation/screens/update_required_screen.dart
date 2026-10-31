import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_system_ui.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/layout/luma_logo.dart';

/// Screen that blocks the entire app when the installed version is below the
/// minimum required one (see the `check-app-version` Edge Function).
///
/// Uses the same dark brand gradient background as the rest of the app in
/// [AppShellScreen] and the login screen, but with no illustration or button:
/// there is nothing to do here except wait for an admin to enable a new
/// version.
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
                                const _UpdatePod(),
                                const SizedBox(height: 24),
                                const Text(
                                  'Luma',
                                  style: AppTextStyles.authTitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.authCardBorder
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    message ?? _defaultMessage,
                                    style: AppTextStyles.authSubtitle.copyWith(
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                    textAlign: TextAlign.center,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdatePod extends StatelessWidget {
  const _UpdatePod();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.authAccentDark.withValues(alpha: 0.5),
            AppColors.authAccentDark.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(
          color: AppColors.authAccent.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.authAccent.withValues(alpha: 0.22),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.system_update_rounded,
          size: 42,
          color: AppColors.authAccent,
        ),
      ),
    );
  }
}
