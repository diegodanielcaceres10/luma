import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_env.dart';
import 'features/app_update/data/models/version_check_result.dart';
import 'features/app_update/data/services/app_update_service.dart';
import 'features/app_update/presentation/screens/update_required_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  final blocked = await _checkVersionBlocked();
  if (blocked != null) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: UpdateRequiredScreen(message: blocked.message),
    ));
    return;
  }

  runApp(const LumaApp());
}

/// Llama a la Edge Function `check-app-version` y devuelve el resultado
/// solo si el estado es "blocked" — los otros dos escenarios ("updated" /
/// "outdated_but_usable") todavía no están implementados en el cliente,
/// así que por ahora se ignoran y la app sigue normalmente.
///
/// Cualquier error (sin conexión, función caída, etc.) también se ignora:
/// un problema de red al arrancar no debería trabar la app entera.
///
/// TODO: se fuerza una versión instalada baja ('0.0.1') para poder probar
/// el escenario "blocked" de punta a punta sin depender de la versión real
/// compilada. Reemplazar por `(await PackageInfo.fromPlatform()).version`
/// cuando se agreguen los otros dos escenarios.
Future<VersionCheckResult?> _checkVersionBlocked() async {
  try {
    const forcedTestVersion = '0.0.1';
    final result = await AppUpdateService(Supabase.instance.client)
        .checkVersion(forcedTestVersion);
    if (result.status == VersionCheckStatus.blocked) {
      return result;
    }
  } catch (_) {
    // Sin conexión, función caída, etc.: no bloqueamos por esto.
  }
  return null;
}
