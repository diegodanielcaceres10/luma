import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/app_system_ui.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_env.dart';
import 'features/app_update/data/models/version_check_result.dart';
import 'features/app_update/data/services/app_update_service.dart';
import 'features/app_update/presentation/screens/update_required_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Se fija acá, antes de mostrar cualquier UI, para que ya esté
  // aplicado tanto en la app normal como en la pantalla de bloqueo por
  // versión (ver `versionCheck?.status == VersionCheckStatus.blocked`
  // más abajo) — ver app/theme/app_system_ui.dart.
  SystemChrome.setSystemUIOverlayStyle(appStatusBarStyle);
  // Sin esto, go_router arma URLs con "#" en Web (ej. /#/movements) — no
  // afecta a mobile/desktop, ahí no hay URL de por medio.
  usePathUrlStrategy();
  await initializeDateFormatting('es');

  if (AppEnv.supabaseUrl.isEmpty || AppEnv.supabasePublishableKey.isEmpty) {
    throw StateError(
      'Faltan SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY. Ejecutá la app con '
      '--dart-define-from-file=.env (ver README).',
    );
  }

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabasePublishableKey,
  );

  final versionCheck = await _checkAppVersion();

  if (versionCheck?.status == VersionCheckStatus.blocked) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: UpdateRequiredScreen(message: versionCheck!.message),
    ));
    return;
  }

  // "outdated_but_usable": se deja entrar a la app, pero con un mensaje
  // pendiente que LumaApp muestra como diálogo al terminar de armar la
  // primera pantalla (ver app/app.dart). "updated" o error de red: null,
  // no se muestra nada.
  final pendingUpdateMessage =
      versionCheck?.status == VersionCheckStatus.outdatedButUsable
          ? versionCheck!.message
          : null;

  runApp(LumaApp(pendingUpdateMessage: pendingUpdateMessage));
}

/// Llama a la Edge Function `check-app-version` con la versión instalada
/// (`PackageInfo`, la real, ya sin forzar nada). Cualquier error (sin
/// conexión, función caída, etc.) devuelve `null`: un problema de red al
/// arrancar no debería trabar la app ni mostrar avisos de más.
Future<VersionCheckResult?> _checkAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return await AppUpdateService(Supabase.instance.client)
        .checkVersion(info.version);
  } catch (_) {
    return null;
  }
}
