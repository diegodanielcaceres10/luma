import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Sin esto, go_router arma URLs con "#" en Web (ej. /#/movements) — no
  // afecta a mobile/desktop, ahí no hay URL de por medio.
  usePathUrlStrategy();
  await initializeDateFormatting('es');

  // Status bar transparente con iconos claros, fijo para toda la app
  // (antes solo se aplicaba en LoginScreen vía AnnotatedRegion).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
    ),
  );

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
  runApp(const LumaApp());
}
