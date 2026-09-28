import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/receipt_scan_result.dart';

/// Sends a receipt photo to the `gemini-image-reader` Edge Function.
/// The image is only sent in memory and is never stored.
class ReceiptScanService {
  final SupabaseClient _client;

  ReceiptScanService(this._client);

  Future<ReceiptScanResult> scan({
    required List<int> imageBytes,
    required String mimeType,
  }) async {
    final response = await _client.functions.invoke(
      'gemini-image-reader',
      body: {
        'image_base64': base64Encode(imageBytes),
        'mime_type': mimeType,
      },
    );

    final data = response.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['error'] != null) {
        throw Exception(map['error'].toString());
      }
      return ReceiptScanResult.fromMap(map);
    }

    throw Exception('Respuesta inesperada al leer el ticket.');
  }
}
