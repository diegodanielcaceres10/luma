import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/domain/notification_health_rule.dart';
import 'package:luma/features/notifications/domain/notification_log_entry.dart';

void main() {
  group('notificationHealthIssue', () {
    final now = DateTime(2026, 10, 16, 12);

    test('reports a denied permission first', () {
      expect(
        notificationHealthIssue(
          allowed: false,
          lastRunAt: now,
          baselineAt: now,
          now: now,
        ),
        NotificationLogKind.permissionDenied,
      );
    });

    test('is healthy when the last run is recent', () {
      expect(
        notificationHealthIssue(
          allowed: true,
          lastRunAt: now.subtract(const Duration(hours: 20)),
          baselineAt: now.subtract(const Duration(days: 10)),
          now: now,
        ),
        isNull,
      );
    });

    test('reports a stale worker after the threshold', () {
      expect(
        notificationHealthIssue(
          allowed: true,
          lastRunAt: now.subtract(kWorkerStaleAfter + const Duration(hours: 1)),
          baselineAt: null,
          now: now,
        ),
        NotificationLogKind.workerStale,
      );
    });

    test('is not stale exactly at the threshold', () {
      expect(
        notificationHealthIssue(
          allowed: true,
          lastRunAt: now.subtract(kWorkerStaleAfter),
          baselineAt: null,
          now: now,
        ),
        isNull,
      );
    });

    test('a task that never ran counts from when it was enabled', () {
      expect(
        notificationHealthIssue(
          allowed: true,
          lastRunAt: null,
          baselineAt: now.subtract(const Duration(hours: 2)),
          now: now,
        ),
        isNull,
      );
      expect(
        notificationHealthIssue(
          allowed: true,
          lastRunAt: null,
          baselineAt: now.subtract(const Duration(days: 3)),
          now: now,
        ),
        NotificationLogKind.workerStale,
      );
    });

    test('uses the later of last run and baseline', () {
      expect(
        notificationHealthIssue(
          allowed: true,
          lastRunAt: now.subtract(const Duration(days: 5)),
          baselineAt: now.subtract(const Duration(hours: 1)),
          now: now,
        ),
        isNull,
      );
    });

    test('has nothing to compare without any reference', () {
      expect(
        notificationHealthIssue(
          allowed: true,
          lastRunAt: null,
          baselineAt: null,
          now: now,
        ),
        isNull,
      );
    });
  });
}
