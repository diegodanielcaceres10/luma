import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and writes the `device_tokens` table (see
/// db/migrations/V002__device_tokens.sql).
class DeviceTokenService {
  final SupabaseClient _client;

  DeviceTokenService(this._client);

  /// Stores [token] for the signed-in user. A token that belonged to another
  /// account (same phone, new login) moves to this one.
  Future<void> register({
    required String token,
    required String platform,
  }) async {
    await _client.rpc('register_device_token', params: {
      'p_token': token,
      'p_platform': platform,
    });
  }

  /// Row level security limits the delete to the user's own rows.
  Future<void> unregister(String token) async {
    await _client.from('device_tokens').delete().eq('token', token);
  }
}
