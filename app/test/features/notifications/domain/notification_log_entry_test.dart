import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/domain/notification_log_entry.dart';

void main() {
  group('NotificationLogEntry', () {
    test('survives a JSON round trip', () {
      final entry = NotificationLogEntry(
        at: DateTime(2026, 10, 16, 9, 30),
        kind: NotificationLogKind.runFailed,
        shown: 2,
        detail: 'boom',
      );

      final parsed = NotificationLogEntry.tryFromJson(entry.toJson());

      expect(parsed, isNotNull);
      expect(parsed!.at, entry.at);
      expect(parsed.kind, NotificationLogKind.runFailed);
      expect(parsed.shown, 2);
      expect(parsed.detail, 'boom');
    });

    test('returns null for malformed data', () {
      expect(NotificationLogEntry.tryFromJson(null), isNull);
      expect(NotificationLogEntry.tryFromJson('text'), isNull);
      expect(NotificationLogEntry.tryFromJson({'kind': 'runOk'}), isNull);
      expect(
        NotificationLogEntry.tryFromJson({
          'at': '2026-10-16T09:30:00',
          'kind': 'unknown',
        }),
        isNull,
      );
    });

    test('defaults missing optional fields', () {
      final parsed = NotificationLogEntry.tryFromJson({
        'at': '2026-10-16T09:30:00',
        'kind': 'runOk',
      });

      expect(parsed!.shown, 0);
      expect(parsed.detail, isNull);
    });

    test('only a healthy run is not a problem', () {
      for (final kind in NotificationLogKind.values) {
        expect(kind.isProblem, kind != NotificationLogKind.runOk);
      }
    });
  });
}
