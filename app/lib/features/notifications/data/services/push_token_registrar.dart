import 'dart:async';

import '../../../../core/diagnostics/error_reporter.dart';
import '../repositories/device_token_repository.dart';
import 'push_messaging_service.dart';

/// Keeps this device's push token in Supabase while the user wants push
/// notifications, and takes it out when they stop.
///
/// Everything here is best effort: a failure is reported and swallowed, so
/// the app never breaks because of push. Callers must not overlap calls;
/// `NotificationsViewModel` runs them one after another.
class PushTokenRegistrar {
  final PushMessagingService _messaging;
  final DeviceTokenRepository _tokens;
  final Future<ErrorReporter> Function() _reporter;
  final Duration _timeout;

  /// [timeout] is how long a plugin or network call may take. A call that
  /// never answers (captive portal, half-dead network) would otherwise block
  /// the calls queued behind it, such as removing the token.
  PushTokenRegistrar({
    required PushMessagingService messaging,
    required DeviceTokenRepository tokens,
    required Future<ErrorReporter> Function() reporter,
    Duration timeout = const Duration(seconds: 20),
  })  : _messaging = messaging,
        _tokens = tokens,
        _reporter = reporter,
        _timeout = timeout;

  StreamSubscription<String>? _refreshSubscription;
  String? _currentToken;

  /// Registers the current token and keeps registering it when FCM rotates
  /// it. Safe to call again: it listens only once.
  Future<void> start() async {
    if (!_messaging.isSupported) return;

    await _cancelRefreshSubscription();
    // Listen before asking for the token, so a failure below does not lose
    // the next refresh.
    _refreshSubscription = _messaging.onTokenRefresh.listen(
      _register,
      onError: _report,
    );

    // Without a time limit: on web this waits for the user to answer the
    // browser prompt.
    try {
      if (!await _messaging.requestPermission()) return;
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
      return;
    }

    String? token;
    try {
      token = await _messaging.getToken().timeout(_timeout);
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
    }
    if (token != null) await _register(token);
  }

  /// The user turned notifications off while signed in: removes the row and
  /// invalidates the token. The row goes first so that no new token is
  /// created in between.
  Future<void> stopAndRemove() async {
    if (!_messaging.isSupported) return;

    await _cancelRefreshSubscription();
    final token = _currentToken;
    _currentToken = null;
    if (token != null) await _guard(() => _tokens.unregister(token));
    await _guard(_messaging.deleteToken);
  }

  /// The session ended: invalidates the token. The row cannot be deleted
  /// without a session, so it stays until the server cleans it up; an
  /// invalidated token no longer receives anything.
  Future<void> release() async {
    if (!_messaging.isSupported) return;

    await _cancelRefreshSubscription();
    _currentToken = null;
    await _guard(_messaging.deleteToken);
  }

  void dispose() {
    _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }

  Future<void> _register(String token) async {
    _currentToken = token;
    await _guard(
      () => _tokens.register(token: token, platform: _messaging.platform),
    );
  }

  Future<void> _cancelRefreshSubscription() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action().timeout(_timeout);
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
    }
  }

  Future<void> _report(Object error, StackTrace stackTrace) async {
    try {
      final reporter = await _reporter();
      await reporter.recordError(
        error,
        stackTrace,
        reason: 'Push token registration',
      );
    } catch (_) {}
  }
}
