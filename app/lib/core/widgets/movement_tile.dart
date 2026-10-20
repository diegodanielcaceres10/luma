import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Marker at the start of a [MovementTile]: an icon for transfers and service
/// payments, a dot in the category color for movements with a category, and a
/// hollow ring for those without one. The ring differs by shape, not color, so
/// it can't be mistaken for a category the user colored gray.
class MovementLeading extends StatelessWidget {
  final IconData? _icon;
  final Color _color;
  final String? _semanticLabel;
  final bool _hollow;

  const MovementLeading.transfer({super.key})
      : _icon = Icons.swap_horiz_rounded,
        _color = AppColors.authTransfer,
        _semanticLabel = 'Transferencia',
        _hollow = false;

  const MovementLeading.servicePayment({super.key})
      : _icon = Icons.request_page_outlined,
        _color = AppColors.authInvoice,
        _semanticLabel = 'Pago de servicio',
        _hollow = false;

  const MovementLeading.category({super.key, required Color color})
      : _icon = null,
        _color = color,
        _semanticLabel = null,
        _hollow = false;

  const MovementLeading.uncategorized({super.key})
      : _icon = null,
        _color = AppColors.authTextSecondary,
        _semanticLabel = 'Sin categoría',
        _hollow = true;

  @override
  Widget build(BuildContext context) {
    final icon = _icon;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.25), width: 1),
      ),
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                color: _color,
                size: 20,
                semanticLabel: _semanticLabel,
              )
            : Semantics(
                label: _semanticLabel,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _hollow ? null : _color,
                    shape: BoxShape.circle,
                    border: _hollow
                        ? Border.all(color: _color, width: 1.5)
                        : null,
                  ),
                ),
              ),
      ),
    );
  }
}

/// One movement in a list:
///
///     [leading]  Description              -21,05 €  [trailing]
///                Category · Date
///
/// A missing or blank [title] shows "Sin descripción" in italics, so the row
/// never repeats the category.
class MovementTile extends StatelessWidget {
  final Widget leading;
  final String? title;

  /// Usually "category · date".
  final String subtitle;
  final String amountText;
  final Color amountColor;

  /// Row actions, such as a menu button.
  final Widget? trailing;

  /// Problem with the movement, shown under the subtitle.
  final String? warning;

  final EdgeInsetsGeometry padding;

  const MovementTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.amountColor,
    this.trailing,
    this.warning,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final description = title?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    final warning = this.warning;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDescription ? description : 'Sin descripción',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: hasDescription
                        ? AppColors.authTextPrimary
                        : AppColors.authTextSecondary,
                    fontStyle:
                        hasDescription ? FontStyle.normal : FontStyle.italic,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.authTextSecondary,
                  ),
                ),
                if (warning != null)
                  Text(
                    warning,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authExpense,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}
