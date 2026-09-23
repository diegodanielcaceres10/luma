import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/version_check_result.dart';

class AppUpdateService {
  final SupabaseClient _client;

  AppUpdateService(this._client);

  /// Invoca la Edge Function `check-app-version`, que compara [version]
  /// contra CURRENT_APP_VERSION / MIN_APP_VERSION (configuradas como
  /// secrets en Supabase) y devuelve el estado correspondiente.
  Future<VersionCheckResult> checkVersion(String version) async {
    final response = await _client.functions.invoke(
      'check-app-version',
      body: {'version': version},
    );
    return VersionCheckResult.fromMap(response.data as Map<String, dynamic>);
  }
}
