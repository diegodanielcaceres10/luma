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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: highlighted ? 0.18 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AppColors.authAccent.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: highlighted
                          ? AppColors.authAccent.withValues(alpha: 0.35)
                          : AppColors.authCardBorder.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 30,
                      color: highlighted
                          ? AppColors.authAccent
                          : AppColors.authTextPrimary,
                    ),
                  ),
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
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.authAccent,
                        ),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (highlighted
                                  ? AppColors.authAccent
                                  : Colors.white)
                              .withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.authAccent,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
