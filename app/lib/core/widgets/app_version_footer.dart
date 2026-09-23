import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Autoría + versión de la app, leídas en runtime desde el build
/// (`PackageInfo`, que a su vez toma el `version` de `pubspec.yaml`) en vez
/// de un texto hardcodeado. Se muestra en el login y en el perfil.
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
      // info.version viene de pubspec.yaml (ej. "1.0.0"); buildNumber es el
      // "+N" (ej. "1"). Se muestran juntos para poder identificar el build
      // exacto instalado (útil en distribuciones de testing).
      _versionLabel = 'v${info.version}+${info.buildNumber}';
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
