import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class EntryModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final bool loading;
  final VoidCallback? onTap;

  const EntryModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = highlighted
        ? Color.alphaBlend(
            AppColors.authAccent.withValues(alpha: 0.12),
            AppColors.authCardFill,
          )
        : AppColors.authCardFill;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: highlighted ? AppColors.authAccent : AppColors.authCardBorder,
        width: highlighted ? 1.5 : 1,
      ),
    );

    return Material(
      color: fill,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.authAccent.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 32, color: AppColors.authTextPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.authTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.authAccent,
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded,
                      color: AppColors.authAccent),
            ],
          ),
        ),
      ),
    );
  }
}
