import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_version_footer.dart';
import '../view_models/auth_view_model.dart';

class ProfileScreen extends StatelessWidget {
  final AuthViewModel viewModel;

  /// Navega a la pantalla de preferencias ('/profile/preferences' — ver
  /// router.dart). Se recibe por callback, igual que el resto de la
  /// navegación de esta app (ver AccountsTab.onAdd, etc.), para no atar
  /// esta pantalla a go_router directamente.
  final VoidCallback onOpenPreferences;

  const ProfileScreen({
    super.key,
    required this.viewModel,
    required this.onOpenPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.authAccentDark.withValues(alpha: 0.35),
              child: Text(
                viewModel.initials,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authTextPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.displayName,
                    style: AppTextStyles.authTitle.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  if (viewModel.email != null)
                    Text(
                      viewModel.email!,
                      style: AppTextStyles.authSubtitle.copyWith(fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _ProfileCard(
          children: [
            _ProfileRow(
              icon: Icons.person_outline_rounded,
              label: 'Nombre',
              value: viewModel.displayName,
            ),
            _ProfileRow(
              icon: Icons.mail_outline_rounded,
              label: 'Correo electrónico',
              value: viewModel.email ?? '—',
              showDivider: false,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _NavigationEntry(
          icon: Icons.tune_rounded,
          label: 'Preferencias',
          onTap: onOpenPreferences,
        ),
        const SizedBox(height: 12),
        _SignOutButton(onPressed: viewModel.signOut),
        const SizedBox(height: 24),
        const AppVersionFooter(
          style: AppTextStyles.authFooter,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.authIconBg,
                child: Icon(icon, size: 18, color: AppColors.authTextPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            AppTextStyles.authSubtitle.copyWith(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.authTextFooter,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.authCardBorder),
      ],
    );
  }
}

class _NavigationEntry extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authCardFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.authCardBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.authTextPrimary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authTextPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.authTextFooter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SignOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authCardFill,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.authCardBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 14),
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
