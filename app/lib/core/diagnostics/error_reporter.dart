/// Where handled errors are sent so they can be reviewed remotely.
///
/// Reporting is best effort: implementations must never throw, because a
/// problem in diagnostics must not break the feature being diagnosed.
abstract interface class ErrorReporter {
  /// Reports an error that was caught, with the stack trace where it
  /// happened. [reason] is a short note on what the app was doing.
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  });
}

/// Discards every report. Used where Crashlytics is not available (web) and
/// when it fails to start.
class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {}
}
