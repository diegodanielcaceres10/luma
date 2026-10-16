import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/data/repositories/notification_log_repository.dart';
import 'package:luma/features/notifications/domain/notification_log_entry.dart';

import '../../../helpers/fakes.dart';

NotificationLogEntry entryAt(int minute) => NotificationLogEntry(
      at: DateTime(2026, 10, 16, 9, minute),
      kind: NotificationLogKind.runOk,
      shown: minute,
    );

void main() {
  late InMemoryNotificationLogStore store;
  late NotificationLogRepository repository;

  setUp(() {
    store = InMemoryNotificationLogStore();
    repository = NotificationLogRepository(store: store);
  });

  group('NotificationLogRepository', () {
    test('starts empty', () async {
      expect(await repository.entries(), isEmpty);
      expect(await repository.lastRunAt(), isNull);
      expect(await repository.baselineAt(), isNull);
    });

    test('lists the newest entry first', () async {
      await repository.record(entryAt(1));
      await repository.record(entryAt(2));

      final entries = await repository.entries();

      expect(entries.map((e) => e.shown), [2, 1]);
    });

    test('keeps only the latest entries', () async {
      for (var i = 0; i < NotificationLogRepository.maxEntries + 5; i++) {
        await repository.record(entryAt(i));
      }

      final entries = await repository.entries();

      expect(entries, hasLength(NotificationLogRepository.maxEntries));
      expect(entries.first.shown, NotificationLogRepository.maxEntries + 4);
    });

    test('recordRun also stores the last run time', () async {
      final entry = entryAt(5);

      await repository.recordRun(entry);

      expect(await repository.lastRunAt(), entry.at);
      expect(await repository.entries(), hasLength(1));
    });

    test('record does not touch the last run time', () async {
      await repository.record(entryAt(5));

      expect(await repository.lastRunAt(), isNull);
    });

    test('ensureBaseline keeps the first value', () async {
      final first = DateTime(2026, 10, 1);

      await repository.ensureBaseline(first);
      await repository.ensureBaseline(DateTime(2026, 10, 9));

      expect(await repository.baselineAt(), first);
    });

    test('clearBaseline forgets the baseline', () async {
      await repository.ensureBaseline(DateTime(2026, 10, 1));

      await repository.clearBaseline();

      expect(await repository.baselineAt(), isNull);
    });

    test('ignores a corrupted log', () async {
      store.values['notifications.log'] = 'not json';

      expect(await repository.entries(), isEmpty);
    });

    test('skips malformed items and keeps the rest', () async {
      await repository.record(entryAt(1));
      store.values['notifications.log'] =
          '[{"bad":true},${store.values['notifications.log']!.substring(1)}';

      expect(await repository.entries(), hasLength(1));
    });

    test('never throws when the store fails', () async {
      store.failing = true;

      await repository.record(entryAt(1));
      await repository.recordRun(entryAt(2));
      await repository.ensureBaseline(DateTime(2026, 10, 1));
      await repository.clearBaseline();

      expect(await repository.entries(), isEmpty);
      expect(await repository.lastRunAt(), isNull);
      expect(await repository.baselineAt(), isNull);
    });
  });
}
