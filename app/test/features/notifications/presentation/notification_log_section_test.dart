import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/data/repositories/notification_log_repository.dart';
import 'package:luma/features/notifications/domain/notification_log_entry.dart';
import 'package:luma/features/notifications/presentation/widgets/notification_log_section.dart';

import '../../../helpers/fakes.dart';

void main() {
  late NotificationLogRepository repository;

  setUp(() {
    repository = NotificationLogRepository(
      store: InMemoryNotificationLogStore(),
    );
  });

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationLogSection(repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('NotificationLogSection', () {
    testWidgets('says the check never ran', (tester) async {
      await pumpSection(tester);

      expect(find.text('Todavía no se ejecutó'), findsOneWidget);
    });

    testWidgets('shows the last run and no warning when healthy',
        (tester) async {
      await repository.recordRun(
        NotificationLogEntry(
          at: DateTime(2026, 10, 16, 9, 30),
          kind: NotificationLogKind.runOk,
          shown: 1,
        ),
      );

      await pumpSection(tester);

      expect(find.text('16/10/2026 09:30'), findsOneWidget);
      expect(
        find.text(
          notificationLogProblemMessage(NotificationLogKind.runFailed)!,
        ),
        findsNothing,
      );
    });

    testWidgets('warns when the newest entry is a problem', (tester) async {
      await repository.record(
        NotificationLogEntry(
          at: DateTime(2026, 10, 16, 9),
          kind: NotificationLogKind.permissionDenied,
        ),
      );

      await pumpSection(tester);

      expect(
        find.text(
          notificationLogProblemMessage(NotificationLogKind.permissionDenied)!,
        ),
        findsOneWidget,
      );
    });

    testWidgets('lists the entries with their detail on demand',
        (tester) async {
      await repository.recordRun(
        NotificationLogEntry(
          at: DateTime(2026, 10, 16, 9, 30),
          kind: NotificationLogKind.runFailed,
          detail: 'Vencimientos: boom',
        ),
      );
      await pumpSection(tester);
      expect(find.text('Vencimientos: boom'), findsNothing);

      await tester.tap(find.text('Ver registro'));
      await tester.pumpAndSettle();

      expect(find.text('Vencimientos: boom'), findsOneWidget);
      expect(find.textContaining('Revisión con errores'), findsOneWidget);

      await tester.tap(find.text('Ocultar registro'));
      await tester.pumpAndSettle();

      expect(find.text('Vencimientos: boom'), findsNothing);
    });

    testWidgets('shows an empty log message', (tester) async {
      await pumpSection(tester);

      await tester.tap(find.text('Ver registro'));
      await tester.pumpAndSettle();

      expect(find.text('Sin registros todavía.'), findsOneWidget);
    });
  });
}
