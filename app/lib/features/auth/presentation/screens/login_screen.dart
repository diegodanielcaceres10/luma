import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/luma_logo.dart';
import '../widgets/google_sign_in_button.dart';
import '../view_models/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  final AuthViewModel viewModel;

  const LoginScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_handleViewModelChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_handleViewModelChange);
    super.dispose();
  }

  void _handleViewModelChange() {
    final error = widget.viewModel.errorMessage;
    if (error != null && error != _lastShownError) {
      _lastShownError = error;
      _showErrorToast(error);
    } else if (error == null) {
      _lastShownError = null;
    }
  }

  // "Toast" con el detalle del error (en Android/iOS no hay Toast nativo
  // accesible desde Flutter sin un plugin nuevo; el SnackBar es el
  // equivalente estándar y permite copiar el texto completo).
  void _showErrorToast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(message),
        action: SnackBarAction(
          label: 'Copiar',
          onPressed: () => Clipboard.setData(ClipboardData(text: message)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light, // Android
            statusBarBrightness: Brightness.dark, // iOS
          ),
          child: Scaffold(
            body: Stack(
              children: [
                // Background image.
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/login_bg.png',
                    fit: BoxFit.cover,
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
                              // Selectable para poder copiar el detalle del
                              // error (código/descripción) sin depender del
                              // SnackBar si ya desapareció.
                              SelectableText(
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
          ),
        );
      },
    );
  }
}
