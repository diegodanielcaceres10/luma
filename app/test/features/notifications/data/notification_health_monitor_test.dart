import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/data/repositories/notification_log_repository.dart';
import 'package:luma/features/notifications/data/services/notification_health_issue.dart';
import 'package:luma/features/notifications/data/services/notification_health_monitor.dart';
import 'package:luma/features/notifications/domain/notification_health_rule.dart';
import 'package:luma/features/notifications/domain/notification_log_entry.dart';

import '../../../helpers/fakes.dart';

void main() {
  late InMemoryNotificationLogStore store;
  late NotificationLogRepository log;
  late DateTime now;
  late bool allowed;
  late FakeErrorReporter reporter;
  late NotificationHealthMonitor monitor;

  setUp(() {
    store = InMemoryNotificationLogStore();
    log = NotificationLogRepository(store: store);
    now = DateTime(2026, 10, 16, 9);
    allowed = true;
    reporter = FakeErrorReporter();
    monitor = NotificationHealthMonitor(
      log: log,
      notificationsAllowed: () async => allowed,
      reporter: () async => reporter,
      now: () => now,
    );
  });

  group('NotificationHealthMonitor', () {
    test('logs nothing when the first check finds no problem', () async {
      await monitor.check();

      expect(await log.entries(), isEmpty);
      expect(await log.baselineAt(), now);
    });

    test('logs a denied permission', () async {
      allowed = false;

      await monitor.check();

      final entries = await log.entries();
      expect(entries, hasLength(1));
      expect(entries.first.kind, NotificationLogKind.permissionDenied);
    });

    test('does not repeat the same problem within 12 hours', () async {
      allowed = false;
      await monitor.check();

      now = now.add(const Duration(hours: 11));
      await monitor.check();

      expect(await log.entries(), hasLength(1));
    });

    test('repeats the problem after 12 hours', () async {
      allowed = false;
      await monitor.check();

      now = now.add(NotificationHealthMonitor.repeatAfter);
      await monitor.check();

      expect(await log.entries(), hasLength(2));
    });

    test('logs a stale worker once the threshold passes', () async {
      await monitor.check();

      now = now.add(kWorkerStaleAfter + const Duration(hours: 1));
      await monitor.check();

      final entries = await log.entries();
      expect(entries.single.kind, NotificationLogKind.workerStale);
      expect(entries.single.detail, contains('ninguna revisión'));
    });

    test('a recent run keeps the worker healthy', () async {
      await monitor.check();

      now = now.add(const Duration(days: 3));
      await log.recordRun(
        NotificationLogEntry(at: now, kind: NotificationLogKind.runOk),
      );
      await monitor.check();

      expect(
        (await log.entries()).where((e) => e.kind.isProblem),
        isEmpty,
      );
    });

    test('reset starts the stale clock again', () async {
      await monitor.check();
      await monitor.reset();

      now = now.add(const Duration(days: 5));
      await monitor.check();

      expect(await log.entries(), isEmpty);
    });

    test('never throws', () async {
      store.failing = true;

      await monitor.check();
      await monitor.reset();
    });
  });

  group('NotificationHealthMonitor reporting', () {
    test('reports nothing when there is no problem', () async {
      await monitor.check();

      expect(reporter.reports, isEmpty);
    });

    test('reports a denied permission', () async {
      allowed = false;

      await monitor.check();

      final report = reporter.reports.single;
      expect(report.error, isA<NotificationHealthIssue>());
      expect(
        (report.error as NotificationHealthIssue).kind,
        NotificationLogKind.permissionDenied,
      );
      expect(report.reason, 'Notification health check');
    });

    test('reports a stale worker with the detail of the log', () async {
      await monitor.check();

      now = now.add(kWorkerStaleAfter + const Duration(hours: 1));
      await monitor.check();

      final issue = reporter.reports.single.error as NotificationHealthIssue;
      expect(issue.kind, NotificationLogKind.workerStale);
      expect(issue.detail, contains('ninguna revisión'));
    });

    test('does not report the same problem within 12 hours', () async {
      allowed = false;
      await monitor.check();

      now = now.add(const Duration(hours: 11));
      await monitor.check();

      expect(reporter.reports, hasLength(1));
    });

    test('reports the problem again after 12 hours', () async {
      allowed = false;
      await monitor.check();

      now = now.add(NotificationHealthMonitor.repeatAfter);
      await monitor.check();

      expect(reporter.reports, hasLength(2));
    });

    test('logs the problem even when the reporter cannot start', () async {
      allowed = false;
      monitor = NotificationHealthMonitor(
        log: log,
        notificationsAllowed: () async => allowed,
        reporter: () async => throw StateError('no reporter'),
        now: () => now,
      );

      await monitor.check();

      expect(
        (await log.entries()).single.kind,
        NotificationLogKind.permissionDenied,
      );
    });

    test('reports the problem even when the log cannot be written', () async {
      allowed = false;
      store.failing = true;

      await monitor.check();

      expect(reporter.reports, hasLength(1));
    });
  });
}
