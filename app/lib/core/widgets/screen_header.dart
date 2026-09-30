import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

enum ScreenHeaderSize { large, compact }

/// Shared screen header: optional back button, title, optional subtitle and
/// an optional trailing [action] slot ([HeaderAddButton], [HeaderMenuButton]).
///
/// Adds no outer padding or bottom spacing; the caller controls both.
class ScreenHeader extends StatelessWidget {
  final String title;

  final String? subtitle;

  final VoidCallback? onBack;

  /// `false` keeps the back button visible but disabled (e.g. while saving).
  final bool backEnabled;

  final Widget? action;

  final ScreenHeaderSize size;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.backEnabled = true,
    this.action,
    this.size = ScreenHeaderSize.large,
  });

  TextStyle get _titleStyle => switch (size) {
        ScreenHeaderSize.large => AppTextStyles.authTitle,
        ScreenHeaderSize.compact => const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.authTextPrimary,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final action = this.action;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              _BackButton(onPressed: backEnabled ? onBack : null),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              action,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.authSubtitle),
        ],
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Volver',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.arrow_back_rounded,
            color: onPressed == null
                ? AppColors.authTextPrimary.withValues(alpha: 0.4)
                : AppColors.authTextPrimary,
          ),
        ),
      ),
    );
  }
}

class HeaderAddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final String tooltip;

  const HeaderAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Agregar',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(Icons.add_rounded),
      color: AppColors.authTextPrimary,
    );
  }
}

class HeaderMenuItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  /// Uses the expense color, for destructive or irreversible actions.
  final bool destructive;

  const HeaderMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
  });
}

class HeaderMenuButton<T> extends StatelessWidget {
  final List<HeaderMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  final bool enabled;

  final String tooltip;

  const HeaderMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.enabled = true,
    this.tooltip = 'Más opciones',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      enabled: enabled,
      tooltip: tooltip,
      onSelected: onSelected,
      color: AppColors.authBackgroundBottom,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      icon: Icon(
        Icons.more_vert_rounded,
        color: enabled
            ? AppColors.authTextPrimary
            : AppColors.authTextPrimary.withValues(alpha: 0.4),
      ),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: _MenuItemContent(item: item),
          ),
      ],
    );
  }
}

class _MenuItemContent extends StatelessWidget {
  final HeaderMenuItem<dynamic> item;

  const _MenuItemContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final color =
        item.destructive ? AppColors.authExpense : AppColors.authTextPrimary;

    return Row(
      children: [
        if (item.icon != null) ...[
          Icon(item.icon, size: 20, color: color),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Text(
            item.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
