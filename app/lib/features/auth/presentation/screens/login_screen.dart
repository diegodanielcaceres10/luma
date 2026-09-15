import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../widgets/google_sign_in_button.dart';
import '../view_models/auth_view_model.dart';

class LoginScreen extends StatelessWidget {
  final AuthViewModel viewModel;

  const LoginScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          body: Stack(
            children: [
              // Background gradient.
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
              // Decorative glow, top-right corner.
              Positioned(
                top: -120,
                right: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.authGlow.withValues(alpha: 0.55),
                        AppColors.authGlow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 4),
                          const LumaLogo(size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Luma',
                            style: AppTextStyles.authTitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Inicia sesión para continuar\ncon tu planificación financiera.',
                            style: AppTextStyles.authSubtitle,
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(flex: 3),
                          GoogleSignInButton(
                            isLoading: viewModel.isLoading,
                            onPressed: viewModel.signInWithGoogle,
                          ),
                          if (viewModel.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              viewModel.errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const Spacer(flex: 5),
                          const Text(
                            'Desarrollado por Diego Caceres\nv1.0.0',
                            style: AppTextStyles.authFooter,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                        ],
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
}
