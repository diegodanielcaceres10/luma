import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'error_reporter.dart';

/// Sends handled errors to Firebase Crashlytics.
///
/// Crashlytics is only set up for Android, so everywhere else [create]
/// returns a [NoopErrorReporter]. Non-fatal reports are written to disk and
/// uploaded the next time the app starts, not right away.
class CrashlyticsErrorReporter implements ErrorReporter {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsErrorReporter._(this._crashlytics);

  /// One start attempt per isolate: the app and the background task each run
  /// in their own isolate and need their own Firebase instance.
  static Future<ErrorReporter>? _instance;

  static bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Starts Firebase in the current isolate, once, and returns the reporter.
  /// Never throws: if Crashlytics is unavailable or fails to start, the
  /// result is a [NoopErrorReporter].
  static Future<ErrorReporter> create() => _instance ??= _start();

  static Future<ErrorReporter> _start() async {
    if (!_isSupported) return const NoopErrorReporter();

    try {
      // Without options, Android reads the config from google-services.json.
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      return CrashlyticsErrorReporter._(FirebaseCrashlytics.instance);
    } catch (_) {
      return const NoopErrorReporter();
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }
}
