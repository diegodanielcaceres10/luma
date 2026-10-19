import '../diagnostics/error_reporter.dart';
import 'scan_failure.dart';

/// Runs a scan so that its callers only ever see a [ScanFailure].
///
/// Whatever [action] throws is classified. When the failure points to a
/// problem worth knowing about (see [ScanFailure.shouldReport]), it is sent
/// to the [ErrorReporter] as a non-fatal error with the given [reason].
/// Reporting never changes the outcome: if the reporter cannot start or
/// fails, the [ScanFailure] is thrown anyway.
Future<T> runScan<T>({
  required String function,
  required String reason,
  required Future<ErrorReporter> Function() reporter,
  required Future<T> Function() action,
}) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    final failure = ScanFailure.fromError(function, error);
    if (failure.shouldReport) {
      await _report(reporter, failure, stackTrace, reason);
    }
    throw failure;
  }
}

Future<void> _report(
  Future<ErrorReporter> Function() reporter,
  ScanFailure failure,
  StackTrace stackTrace,
  String reason,
) async {
  try {
    await (await reporter()).recordError(
      failure,
      stackTrace,
      reason: reason,
    );
  } catch (_) {
    // A broken reporter must not hide the failure from the user.
  }
}
