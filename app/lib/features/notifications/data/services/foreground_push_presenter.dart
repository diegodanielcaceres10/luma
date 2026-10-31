import 'dart:async';

import '../../../../core/diagnostics/error_reporter.dart';
import 'local_notifications_service.dart';
import 'push_messaging_service.dart';

/// Shows push messages that arrive while the app is open. Android only
/// displays them by itself when the app is in the background.
///
/// Best effort, like `PushTokenRegistrar`: a failure is reported and the
/// listener keeps going.
class ForegroundPushPresenter {
  final PushMessagingService _messaging;
  final LocalNotificationsService _notifications;
  final Future<ErrorReporter> Function() _reporter;

  ForegroundPushPresenter({
    required PushMessagingService messaging,
    required LocalNotificationsService notifications,
    required Future<ErrorReporter> Function() reporter,
  })  : _messaging = messaging,
        _notifications = notifications,
        _reporter = reporter;

  StreamSubscription<PushMessage>? _subscription;

  /// Starts listening. Safe to call again: it listens only once.
  Future<void> start() async {
    if (!_messaging.showsForegroundMessages || _subscription != null) return;

    _subscription = _messaging.onForegroundMessage.listen(
      _show,
      onError: _report,
      // If the stream ends (for example Firebase failed to start), a later
      // start() must be able to listen again.
      onDone: () => _subscription = null,
    );
  }

  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _show(PushMessage message) async {
    final title = message.title;
    final body = message.body;
    if (title == null || title.trim().isEmpty) return;
    if (body == null || body.trim().isEmpty) return;

    try {
      await _notifications.showPush(
        // Same tag, same id: a repeated delivery replaces the notice.
        id: (message.tag ?? title).hashCode & 0x7fffffff,
        title: title,
        body: body,
      );
    } catch (error, stackTrace) {
      await _report(error, stackTrace);
    }
  }

  Future<void> _report(Object error, StackTrace stackTrace) async {
    try {
      final reporter = await _reporter();
      await reporter.recordError(error, stackTrace, reason: 'Foreground push');
    } catch (_) {}
  }
}
