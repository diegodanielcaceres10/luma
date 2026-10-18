import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/data/services/notification_health_issue.dart';
import 'package:luma/features/notifications/domain/notification_log_entry.dart';

void main() {
  group('NotificationHealthIssue', () {
    test('names the kind of problem', () {
      const issue =
          NotificationHealthIssue(kind: NotificationLogKind.permissionDenied);

      expect(issue.toString(), 'NotificationHealthIssue(permissionDenied)');
    });

    test('adds the detail when there is one', () {
      const issue = NotificationHealthIssue(
        kind: NotificationLogKind.workerStale,
        detail: 'Última revisión: 16/10/2026 09:00.',
      );

      expect(
        issue.toString(),
        'NotificationHealthIssue(workerStale): Última revisión: 16/10/2026 09:00.',
      );
    });

    test('is an Exception', () {
      const issue =
          NotificationHealthIssue(kind: NotificationLogKind.workerStale);

      expect(issue, isA<Exception>());
    });
  });
}
