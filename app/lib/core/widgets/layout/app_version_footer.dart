import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme/app_colors.dart';

/// App author and version, read at runtime from `PackageInfo` instead of
/// hardcoded text.
class AppVersionFooter extends StatefulWidget {
  final TextStyle? style;
  final TextAlign textAlign;

  const AppVersionFooter({
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  State<AppVersionFooter> createState() => _AppVersionFooterState();
}

class _AppVersionFooterState extends State<AppVersionFooter> {
  static const _author = 'Desarrollado por Diego Caceres';

  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = 'v${info.version}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = _versionLabel;
    final authorStyle = widget.style?.copyWith(
          color: AppColors.authTextSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ) ??
        const TextStyle(
          color: AppColors.authTextSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.3,
        );

    final versionStyle = TextStyle(
      color: AppColors.authTextSecondary.withValues(alpha: 0.75),
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      height: 1.3,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _author,
            style: authorStyle,
            textAlign: widget.textAlign,
          ),
          if (version != null) ...[
            const SizedBox(height: 2),
            Text(
              version,
              style: versionStyle,
              textAlign: widget.textAlign,
            ),
          ],
        ],
      ),
    );
  }
}
