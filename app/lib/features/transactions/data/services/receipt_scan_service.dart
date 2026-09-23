import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/receipt_scan_result.dart';

/// Manda la foto de un ticket/factura a la Edge Function
/// `gemini-image-reader` (Gemini API, tier gratuito) para precompletar el
/// formulario de "Añadir ingreso/gasto".
///
/// POC: la imagen viaja en memoria (base64) solo para esta llamada — no se
/// sube a Supabase Storage ni se guarda en ninguna tabla, ni acá ni en el
/// backend (ver el comentario en la Edge Function, que la descarta apenas
/// obtiene la respuesta del modelo).
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
