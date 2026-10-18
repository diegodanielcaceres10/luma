import '../../../../core/diagnostics/redact_error_message.dart';

/// A failure of the daily notification check, shaped for an error report: it
/// names the check that failed and keeps the type and message of the cause,
/// without ids or email addresses.
class NotificationCheckFailure implements Exception {
  /// Which check failed, for example `Vencimientos`.
  final String check;

  /// The error that was caught.
  final Object cause;

  const NotificationCheckFailure({required this.check, required this.cause});

  @override
  String toString() => 'NotificationCheckFailure($check): '
      '${cause.runtimeType}: ${redactErrorMessage(cause.toString())}';
}
