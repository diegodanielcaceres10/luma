import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scanned_movement.dart';

/// Sends a bank statement screenshot to the `gemini-statement-reader` Edge
/// Function. The image is only sent in memory and is never stored.
class StatementScanService {
  final SupabaseClient _client;

  StatementScanService(this._client);

  Future<List<ScannedMovement>> scan({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    final response = await _client.functions.invoke(
      'gemini-statement-reader',
      body: {
        'image_base64': base64Encode(imageBytes),
        'mime_type': mimeType,
      },
    );

    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data is! Map) {
      throw Exception('Respuesta inesperada al leer el extracto.');
    }
    return ScannedMovement.listFromResponse(data);
  }
}
