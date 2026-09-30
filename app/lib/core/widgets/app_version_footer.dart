import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    return Text(
      version == null ? _author : '$_author\n$version',
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
