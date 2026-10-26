import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_env.dart';
import '../../features/home/data/models/version_check_result.dart';
import '../../features/home/data/services/app_update_service.dart';

/// What the app should do once its startup work is done.
sealed class BootstrapResult {
  const BootstrapResult();
}

/// The app can start. [pendingUpdateMessage] is set when the installed version
/// is outdated but still usable; LumaApp shows it once the first screen is
/// built.
final class BootstrapReady extends BootstrapResult {
  final String? pendingUpdateMessage;

  const BootstrapReady({this.pendingUpdateMessage});
}

/// The installed version is below the minimum one: only the update-required
/// screen is shown.
final class BootstrapBlocked extends BootstrapResult {
  final String message;

  const BootstrapBlocked(this.message);
}

/// Startup work that used to live in `main()`: starts the backend and checks
/// the installed version. The steps are injected so it can be tested without
/// a network.
class AppInitializer {
  final Future<void> Function() initializeBackend;
  final Future<VersionCheckResult?> Function() checkVersion;

  const AppInitializer({
    required this.initializeBackend,
    required this.checkVersion,
  });

  factory AppInitializer.production() {
    return AppInitializer(
      initializeBackend: () => Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabasePublishableKey,
      ),
      checkVersion: _checkInstalledVersion,
    );
  }

  /// A backend failure is rethrown: the caller decides how to show it. The
  /// version check never blocks startup on its own errors (see
  /// [_checkInstalledVersion]).
  Future<BootstrapResult> run() async {
    await initializeBackend();
    final version = await checkVersion();

    return switch (version?.status) {
      VersionCheckStatus.blocked => BootstrapBlocked(version!.message),
      VersionCheckStatus.outdatedButUsable =>
        BootstrapReady(pendingUpdateMessage: version!.message),
      _ => const BootstrapReady(),
    };
  }
}

/// Calls the `check-app-version` Edge Function with the installed version
/// (`PackageInfo`, the real one, nothing forced). Any error (no connection,
/// function down, etc.) returns `null`: a network problem at startup should
/// neither block the app nor show unnecessary warnings.
Future<VersionCheckResult?> _checkInstalledVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return await AppUpdateService(Supabase.instance.client)
        .checkVersion(info.version);
  } catch (_) {
    return null;
  }
}
