import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_text_styles.dart';

class DashboardGreetingRow extends StatelessWidget {
  final String initials;
  final String firstName;

  const DashboardGreetingRow(
      {super.key, required this.initials, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.authAccentDark.withValues(alpha: 0.35),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.authTextPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName 👋',
                style: AppTextStyles.authTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              const Text(
                'Aquí tienes un resumen de tus finanzas.',
                style: AppTextStyles.authSubtitle,
              ),
            ],
          ),
        ),
      ],
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.authTextPrimary,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.authTextSecondary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ver todas', style: TextStyle(fontSize: 13)),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
