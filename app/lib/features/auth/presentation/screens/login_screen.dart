import 'package:flutter/material.dart';

import '../../../../app/theme/app_text_styles.dart';
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
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome to Luma',
                        style: AppTextStyles.title,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Take control of your finances.',
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      GoogleSignInButton(
                        isLoading: viewModel.isLoading,
                        onPressed: viewModel.signInWithGoogle,
                      ),
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          viewModel.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
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
