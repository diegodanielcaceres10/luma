import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/version_check_result.dart';

class AppUpdateService {
  final SupabaseClient _client;

  AppUpdateService(this._client);

  /// Invokes the `check-app-version` Edge Function, which compares [version]
  /// against CURRENT_APP_VERSION / MIN_APP_VERSION (configured as Supabase
  /// secrets) and returns the corresponding status.
  Future<VersionCheckResult> checkVersion(String version) async {
    final response = await _client.functions.invoke(
      'check-app-version',
      body: {'version': version},
    );
    return VersionCheckResult.fromMap(response.data as Map<String, dynamic>);
  }
}
