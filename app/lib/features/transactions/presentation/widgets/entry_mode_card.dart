import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Lays out the entry mode cards side by side when there is room and stacks
/// them otherwise. Cards in a row share the same width and height.
class EntryModeOptions extends StatelessWidget {
  /// Narrowest available width that still fits the cards side by side.
  static const double sideBySideMinWidth = 480;

  static const double _gap = 12;

  final List<EntryModeCard> cards;

  const EntryModeOptions({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < sideBySideMinWidth) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: _gap),
                cards[i],
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                Expanded(child: cards[i].asVertical()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class EntryModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final bool loading;

  /// Icon and chevron on top, text below; used when the card is narrow.
  final bool vertical;
  final VoidCallback? onTap;

  const EntryModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.loading = false,
    this.vertical = false,
  });

  EntryModeCard asVertical() => EntryModeCard(
        key: key,
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        highlighted: highlighted,
        loading: loading,
        vertical: true,
      );

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
            child: vertical ? _buildVertical() : _buildHorizontal(),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontal() {
    return Row(
      children: [
        _buildIconBox(),
        const SizedBox(width: 16),
        Expanded(child: _buildText()),
        const SizedBox(width: 8),
        _buildTrailing(),
      ],
    );
  }

  Widget _buildVertical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIconBox(),
            const Spacer(),
            _buildTrailing(),
          ],
        ),
        const SizedBox(height: 16),
        _buildText(),
      ],
    );
  }

  Widget _buildIconBox() {
    return Container(
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
          color:
              highlighted ? AppColors.authAccent : AppColors.authTextPrimary,
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
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
    );
  }

  Widget _buildTrailing() {
    if (loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.authAccent,
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: (highlighted ? AppColors.authAccent : Colors.white)
            .withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.authAccent,
      ),
    );
  }
}
