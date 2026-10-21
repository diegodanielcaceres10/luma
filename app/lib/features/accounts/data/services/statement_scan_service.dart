import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/ai/run_scan.dart';
import '../../../../core/ai/scan_failure.dart';
import '../../../../core/ai/scan_stage.dart';
import '../../../../core/diagnostics/crashlytics_error_reporter.dart';
import '../../../../core/diagnostics/error_reporter.dart';
import '../models/scanned_movement.dart';

/// Sends a bank statement screenshot to the `gemini-statement-reader` Edge
/// Function. The image is only sent in memory and is never stored.
///
/// Every failure is thrown as a [ScanFailure]. The ones that point to a
/// problem are also reported, without the image or anything read from it.
class StatementScanService {
  static const _function = 'gemini-statement-reader';

  final SupabaseClient _client;
  final Future<ErrorReporter> Function() _reporter;

  StatementScanService(
    this._client, {
    Future<ErrorReporter> Function()? reporter,
  }) : _reporter = reporter ?? CrashlyticsErrorReporter.create;

  Future<List<ScannedMovement>> scan({
    required List<int> imageBytes,
    required String mimeType,
    ScanProgress? onStage,
  }) {
    return runScan(
      function: _function,
      reason: 'Statement scan',
      reporter: _reporter,
      action: () async {
        onStage?.call(ScanStage.preparing);
        final body = {
          'image_base64': base64Encode(imageBytes),
          'mime_type': mimeType,
        };

        // Sending the request and waiting for the answer are a single call.
        onStage?.call(ScanStage.sending);
        final response = await _client.functions.invoke(_function, body: body);

        onStage?.call(ScanStage.processing);

        final data = response.data;
        if (data is! Map) {
          throw ScanFailure(
            function: _function,
            kind: ScanFailureKind.parse,
            status: response.status,
          );
        }
        if (data['error'] != null) {
          throw ScanFailure.fromResponse(
            function: _function,
            status: response.status,
            body: data,
          );
        }
        return ScannedMovement.listFromResponse(data);
      },
    );
  }
}
