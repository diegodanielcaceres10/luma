import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_system_ui.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/layout/app_version_footer.dart';
import '../../../../core/widgets/layout/luma_logo.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/google_sign_in_button.dart';

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

  static bool _isDesktop(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isDesktopPlatform = !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux);
    return isDesktopPlatform || MediaQuery.sizeOf(context).width >= 768;
  }

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

  // A SnackBar (instead of a native toast) so the user can copy the full text.
  void _showErrorToast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2922),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: AppColors.authCardBorder,
            width: 1,
          ),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.authTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Copiar',
          textColor: AppColors.authAccent,
          onPressed: () => Clipboard.setData(ClipboardData(text: message)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final isDesktop = _isDesktop(context);
    final bgAsset = isDesktop
        ? 'assets/images/login_bg_desktop_dark.png'
        : 'assets/images/login_bg_mobile_dark.png';

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: appStatusBarStyle,
          child: Scaffold(
            backgroundColor: AppColors.authBackgroundBottom,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    bgAsset,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -60,
                  left: 0,
                  right: 0,
                  height: 320,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.authAccent.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 12 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    const Spacer(flex: 4),
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.authCardFill,
                                        border: Border.all(
                                          color: AppColors.authCardBorder
                                              .withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.authAccent
                                                .withValues(alpha: 0.16),
                                            blurRadius: 28,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const LumaLogo(size: 52),
                                    ),
                                    const SizedBox(height: 22),
                                    const Text(
                                      'Luma',
                                      style: AppTextStyles.authTitle,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 14),
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
                                    const Spacer(flex: 5),
                                    const AppVersionFooter(
                                      style: AppTextStyles.authFooter,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
