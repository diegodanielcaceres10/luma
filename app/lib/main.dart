import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_env.dart';
import 'features/home/data/models/version_check_result.dart';
import 'features/home/data/services/app_update_service.dart';
import 'features/home/presentation/screens/update_required_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs on web (no "#" in routes).
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

  // "outdated_but_usable": the user may enter the app, but with a pending
  // message that LumaApp shows as a dialog once the first screen is built
  // (see app/app.dart). "updated" or network error: null, nothing is shown.
  final pendingUpdateMessage =
      versionCheck?.status == VersionCheckStatus.outdatedButUsable
          ? versionCheck!.message
          : null;

  runApp(LumaApp(pendingUpdateMessage: pendingUpdateMessage));
}

/// Calls the `check-app-version` Edge Function with the installed version
/// (`PackageInfo`, the real one, nothing forced). Any error (no connection,
/// function down, etc.) returns `null`: a network problem at startup should
/// neither block the app nor show unnecessary warnings.
Future<VersionCheckResult?> _checkAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return await AppUpdateService(Supabase.instance.client)
        .checkVersion(info.version);
  } catch (_) {
    return null;
  }
}
