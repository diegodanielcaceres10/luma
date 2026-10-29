import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/data/services/foreground_push_presenter.dart';
import 'package:luma/features/notifications/data/services/push_messaging_service.dart';

import '../../../helpers/fakes.dart';

void main() {
  late List<String> calls;
  late FakePushMessagingService messaging;
  late RecordingLocalNotificationsService notifications;
  late FakeErrorReporter reporter;
  late ForegroundPushPresenter presenter;

  setUp(() {
    calls = [];
    messaging = FakePushMessagingService(calls);
    notifications = RecordingLocalNotificationsService();
    reporter = FakeErrorReporter();
    presenter = ForegroundPushPresenter(
      messaging: messaging,
      notifications: notifications,
      reporter: () async => reporter,
    );
  });

  tearDown(() => presenter.dispose());

  const luz = PushMessage(
    title: 'Vence hoy: Luz',
    body: 'La factura de Luz vence hoy.',
    tag: 'invoice_due:1:2026-11-30',
  );

  group('ForegroundPushPresenter', () {
    test('shows a local notification for a foreground message', () async {
      await presenter.start();
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(notifications.shown, hasLength(1));
      expect(notifications.shown.single.title, 'Vence hoy: Luz');
      expect(notifications.shown.single.body, 'La factura de Luz vence hoy.');
    });

    test('the id is stable per tag, distinct between tags and never negative',
        () async {
      await presenter.start();
      messaging.emitForeground(luz);
      messaging.emitForeground(luz);
      messaging.emitForeground(const PushMessage(
        title: 'Vence hoy: Gas',
        body: 'La factura de Gas vence hoy.',
        tag: 'invoice_due:2:2026-11-30',
      ));
      await pumpEventQueue();

      final ids = notifications.shown.map((n) => n.id).toList();
      expect(ids[0], ids[1]);
      expect(ids[2], isNot(ids[0]));
      expect(ids.every((id) => id >= 0), isTrue);
    });

    test('without a tag the title is used for the id', () async {
      await presenter.start();
      messaging.emitForeground(const PushMessage(title: 'A', body: 'x'));
      messaging.emitForeground(const PushMessage(title: 'A', body: 'y'));
      await pumpEventQueue();

      expect(notifications.shown[0].id, notifications.shown[1].id);
    });

    test('ignores messages without title or body', () async {
      await presenter.start();
      messaging.emitForeground(const PushMessage(body: 'only body'));
      messaging.emitForeground(const PushMessage(title: 'only title'));
      messaging.emitForeground(const PushMessage(title: '  ', body: 'blank'));
      messaging.emitForeground(const PushMessage());
      await pumpEventQueue();

      expect(notifications.shown, isEmpty);
      expect(reporter.reports, isEmpty);
    });

    test('a failure while showing is reported and the listener keeps working',
        () async {
      await presenter.start();
      notifications.showError = StateError('plugin down');
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.reason, 'Foreground push');
      expect(notifications.shown, isEmpty);

      notifications.showError = null;
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(notifications.shown, hasLength(1));
    });

    test('an error in the message stream is reported', () async {
      await presenter.start();
      messaging.emitForegroundError(StateError('stream failed'));
      await pumpEventQueue();

      expect(reporter.reports.single.reason, 'Foreground push');
    });

    test('start is idempotent: one notification per message', () async {
      await presenter.start();
      await presenter.start();
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(notifications.shown, hasLength(1));
      expect(
        calls.where((c) => c == 'onForegroundMessage'),
        hasLength(1),
      );
    });

    test('start listens again after the stream ended', () async {
      await presenter.start();
      await messaging.endForeground();
      await pumpEventQueue();

      await presenter.start();
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(notifications.shown, hasLength(1));
    });

    test('does nothing where foreground messages are not shown', () async {
      messaging.foregroundSupported = false;
      await presenter.start();
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(calls, isEmpty);
      expect(notifications.shown, isEmpty);
    });

    test('does nothing where push is not supported', () async {
      messaging.isSupported = false;
      await presenter.start();
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(calls, isEmpty);
      expect(notifications.shown, isEmpty);
    });

    test('stop ends the listening and start resumes it', () async {
      await presenter.start();
      await presenter.stop();
      messaging.emitForeground(luz);
      await pumpEventQueue();
      expect(notifications.shown, isEmpty);

      await presenter.start();
      messaging.emitForeground(luz);
      await pumpEventQueue();
      expect(notifications.shown, hasLength(1));
    });

    test('a failing reporter does not break the listener', () async {
      presenter = ForegroundPushPresenter(
        messaging: messaging,
        notifications: notifications,
        reporter: () async => throw StateError('no reporter'),
      );
      await presenter.start();
      notifications.showError = StateError('plugin down');
      messaging.emitForeground(luz);
      await pumpEventQueue();

      notifications.showError = null;
      messaging.emitForeground(luz);
      await pumpEventQueue();

      expect(notifications.shown, hasLength(1));
    });
  });
}
