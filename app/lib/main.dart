import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'app/bootstrap/app_initializer.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_env.dart';
import 'core/config/app_info.dart';
import 'core/diagnostics/crashlytics_error_reporter.dart';
import 'core/diagnostics/global_error_handlers.dart';
import 'features/home/presentation/screens/update_required_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs on web (no "#" in routes).
  usePathUrlStrategy();
  await initializeDateFormatting('es');

  // Starts Crashlytics on Android and does nothing elsewhere; never throws.
  final errorReporter = await CrashlyticsErrorReporter.create();
  installGlobalErrorHandlers(errorReporter);

  if (AppEnv.supabaseUrl.isEmpty || AppEnv.supabasePublishableKey.isEmpty) {
    throw StateError(
      'Faltan SUPABASE_URL o SUPABASE_PUBLISHABLE_KEY. Ejecutá la app con '
      '--dart-define-from-file=.env (ver README).',
    );
  }

  // Backend startup and the version check run behind the animated splash (see
  // app/bootstrap/). "outdated_but_usable" reaches LumaApp as a pending
  // message that it shows as a dialog once the first screen is built.
  runApp(AppBootstrap(
    initializer: AppInitializer.production(),
    errorReporter: errorReporter,
    appBuilder: (pendingUpdateMessage) =>
        LumaApp(pendingUpdateMessage: pendingUpdateMessage),
    blockedBuilder: (message) => MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: UpdateRequiredScreen(message: message),
    ),
  ));
}
