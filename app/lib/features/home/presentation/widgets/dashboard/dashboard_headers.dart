import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_text_styles.dart';

class DashboardGreetingRow extends StatelessWidget {
  final String initials;
  final String firstName;

  /// Profile photo shown inside the avatar. When it is `null`, still loading
  /// or fails to load, the avatar shows [initials] instead.
  final String? photoUrl;

  const DashboardGreetingRow({
    super.key,
    required this.initials,
    required this.firstName,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.authAccentDark.withValues(alpha: 0.65),
                AppColors.authAccentDark.withValues(alpha: 0.25),
              ],
            ),
            border: Border.all(
              color: AppColors.authAccent.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.authAccent.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: url == null
                ? _GreetingInitials(initials: initials)
                : _GreetingPhoto(url: url, initials: initials),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName 👋',
                style: AppTextStyles.authTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Aquí tienes un resumen de tus finanzas.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.authTextSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GreetingPhoto extends StatelessWidget {
  final String url;
  final String initials;

  const _GreetingPhoto({required this.url, required this.initials});

  @override
  Widget build(BuildContext context) {
    final fallback = _GreetingInitials(initials: initials);

    return Image.network(
      url,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      // Keeps the initials visible until the first frame is decoded.
      frameBuilder: (context, child, frame, loadedSync) =>
          loadedSync || frame != null ? child : fallback,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class _GreetingInitials extends StatelessWidget {
  final String initials;

  const _GreetingInitials({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.authTextPrimary,
        ),
      ),
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const DashboardSectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(12),
            hoverColor: AppColors.authAccent.withValues(alpha: 0.10),
            splashColor: AppColors.authAccent.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver todos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onSeeAll != null
                          ? AppColors.authAccent
                          : AppColors.authTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: onSeeAll != null
                        ? AppColors.authAccent
                        : AppColors.authTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
