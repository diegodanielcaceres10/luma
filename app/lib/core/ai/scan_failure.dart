import 'package:supabase_flutter/supabase_flutter.dart';

/// Why reading an image with the AI service failed, from the user's side.
enum ScanFailureKind {
  /// The free tier limit was reached. Expected from time to time.
  quota,

  /// The service is not set up correctly (missing, invalid or revoked key,
  /// retired model). Only the administrator can fix it.
  config,

  /// The service answered, but the answer could not be used.
  parse,

  /// The service failed or is down.
  upstream,

  /// No usable answer at all, such as no connection, or an error that does
  /// not tell more.
  unavailable,
}

/// Message for [ScanFailureKind.unavailable] and for errors that are not a
/// [ScanFailure].
const scanUnavailableMessage =
    'Servicio no disponible. Intente más tarde o consulte a su administrador.';

/// A failed attempt to read an image, already classified.
///
/// It is built to be sent as an error report, so it only carries the function
/// name, the kind and the HTTP status. The body of the response is left out
/// on purpose: it could echo data read from the image.
class ScanFailure implements Exception {
  /// Name of the Edge Function that was called.
  final String function;
  final ScanFailureKind kind;

  /// HTTP status of the response, when there was one.
  final int? status;

  const ScanFailure({
    required this.function,
    required this.kind,
    this.status,
  });

  /// Classifies a response of the Edge Function. The function sends a `code`
  /// in the body; for older deployments without it, the status decides.
  factory ScanFailure.fromResponse({
    required String function,
    required int status,
    Object? body,
  }) {
    final code = body is Map ? body['code'] : null;
    final kind = switch (code) {
      'quota' => ScanFailureKind.quota,
      'config' => ScanFailureKind.config,
      'parse' => ScanFailureKind.parse,
      'upstream' => ScanFailureKind.upstream,
      _ => _kindFromStatus(status),
    };
    return ScanFailure(function: function, kind: kind, status: status);
  }

  /// Classifies whatever a scan threw. A failure that is already classified is
  /// kept; a failed function call is read by status and body; anything else
  /// is [ScanFailureKind.unavailable].
  factory ScanFailure.fromError(String function, Object error) {
    if (error is ScanFailure) return error;
    if (error is FunctionException) {
      return ScanFailure.fromResponse(
        function: function,
        status: error.status,
        body: error.details,
      );
    }
    return ScanFailure(function: function, kind: ScanFailureKind.unavailable);
  }

  static ScanFailureKind _kindFromStatus(int status) {
    if (status == 429) return ScanFailureKind.quota;
    if (status >= 500) return ScanFailureKind.upstream;
    return ScanFailureKind.unavailable;
  }

  /// What the user sees. Does not blame the user, and says what to do next.
  String get userMessage => switch (kind) {
        ScanFailureKind.quota =>
          'Se alcanzó el límite de uso del servicio de lectura. '
              'Intente de nuevo más tarde.',
        ScanFailureKind.config =>
          'El servicio de lectura tiene un problema de configuración. '
              'Consulte a su administrador.',
        ScanFailureKind.parse =>
          'No se pudo interpretar la imagen. Pruebe recortando solo el '
              'ticket o con otra captura.',
        ScanFailureKind.upstream =>
          'El servicio de IA no respondió correctamente. '
              'Intente nuevamente en unos minutos.',
        ScanFailureKind.unavailable => scanUnavailableMessage,
      };

  /// Whether it is worth an error report. A quota limit and a lost
  /// connection are expected, and would only bury the real problems.
  bool get shouldReport => switch (kind) {
        ScanFailureKind.config ||
        ScanFailureKind.parse ||
        ScanFailureKind.upstream =>
          true,
        ScanFailureKind.quota || ScanFailureKind.unavailable => false,
      };

  @override
  String toString() {
    final http = status == null ? '' : ' (HTTP $status)';
    return 'ScanFailure($function): ${kind.name}$http';
  }
}
