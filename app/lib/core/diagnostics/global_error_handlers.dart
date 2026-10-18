import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'error_reporter.dart';
import 'redact_error_message.dart';

/// An error that nothing in the app handled, shaped for an error report: it
/// keeps the type and message of the original error, without ids or email
/// addresses.
class UnhandledAppError implements Exception {
  /// The error that reached the global handlers.
  final Object cause;

  const UnhandledAppError(this.cause);

  @override
  String toString() => 'UnhandledAppError: '
      '${cause.runtimeType}: ${redactErrorMessage(cause.toString())}';
}

/// Sends the errors nothing else handled to [reporter]: the ones the Flutter
/// framework reports and the asynchronous ones that escape every zone.
///
/// The handlers that were installed before keep running afterwards, so the
/// errors still show up in the console during development.
void installGlobalErrorHandlers(ErrorReporter reporter) {
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(
      reporter.recordError(
        UnhandledAppError(details.exception),
        details.stack ?? StackTrace.current,
        reason: 'Flutter framework error',
        fatal: true,
      ),
    );
    previousFlutterHandler?.call(details);
  };

  final previousPlatformHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      reporter.recordError(
        UnhandledAppError(error),
        stack,
        reason: 'Uncaught asynchronous error',
        fatal: true,
      ),
    );
    // False leaves the error unhandled, as it was before this was installed.
    return previousPlatformHandler?.call(error, stack) ?? false;
  };
}
