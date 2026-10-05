import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_text_styles.dart';

/// One option of the quick actions menu.
class QuickActionOption {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickActionOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// Circular green floating button with a "+". The quick actions overlay
/// redraws it in the same position with [rotation] to turn it into an "×".
class DashboardAddFab extends StatelessWidget {
  static const double size = 56;

  final VoidCallback onPressed;

  /// Icon rotation, in radians.
  final double rotation;

  const DashboardAddFab({
    super.key,
    required this.onPressed,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Acciones rápidas',
      child: Material(
        color: AppColors.authAccent,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black54,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.authBackgroundBottom,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick actions menu: blurred background over the whole screen, the
/// options stacked above the button and the button in place, now as an "×".
/// Tapping the background, the button or an option closes it.
class DashboardQuickActionsOverlay extends StatelessWidget {
  final Animation<double> animation;

  /// Position of the floating button in screen coordinates.
  final Rect fabRect;
  final List<QuickActionOption> options;
  final VoidCallback onClose;

  const DashboardQuickActionsOverlay({
    super.key,
    required this.animation,
    required this.fabRect,
    required this.options,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeOut.transform(animation.value);

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.45 * t),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: screen.width - fabRect.right,
                bottom: screen.height - fabRect.top + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildOption(i),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: fabRect.left,
                top: fabRect.top,
                child: DashboardAddFab(
                  rotation: t * math.pi / 4,
                  onPressed: onClose,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Staggered entrance: the option closest to the button appears first.
  Widget _buildOption(int index) {
    final option = options[index];
    final start = 0.1 * (options.length - 1 - index);
    final progress = Interval(
      start,
      start + 0.6,
      curve: Curves.easeOutCubic,
    ).transform(animation.value);

    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - progress)),
        child: _QuickActionPill(
          option: option,
          onTap: () {
            onClose();
            option.onTap();
          },
        ),
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  final QuickActionOption option;
  final VoidCallback onTap;

  const _QuickActionPill({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authBackgroundTop,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.authCardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: AppTextStyles.authSubtitle.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              CircleAvatar(
                radius: 18,
                backgroundColor: option.iconColor.withValues(alpha: 0.85),
                child: Icon(option.icon, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
