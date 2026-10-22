import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/ai/scan_progress_timeline.dart';
import 'package:luma/core/ai/scan_stage.dart';
import 'package:luma/core/widgets/scan_progress_dialog.dart';

void main() {
  const second = Duration(seconds: 1);

  late ScanProgressTimeline timeline;

  // The timeline is created inside the test so its timers run on the test's
  // fake clock. It ends with the tree gone and the timeline released: a widget
  // test must finish without pending timers.
  void testDialog(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      timeline = ScanProgressTimeline();
      await body(tester);
      await tester.pumpWidget(const SizedBox());
      timeline.dispose();
    });
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showScanProgressDialog(context, timeline),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> next(WidgetTester tester) async {
    await tester.pump(second);
    await tester.pump(const Duration(milliseconds: 300));
  }

  bool hasIcon(IconData icon) => find.byIcon(icon).evaluate().isNotEmpty;

  testDialog('starts by preparing the image', (tester) async {
    await open(tester);

    expect(find.text('Preparando la imagen'), findsOneWidget);
    expect(hasIcon(Icons.image_outlined), isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testDialog('shows a text and an icon for every stage', (tester) async {
    await open(tester);

    timeline.report(ScanStage.sending);
    await next(tester);
    expect(find.text('Enviando y esperando respuesta'), findsOneWidget);
    expect(hasIcon(Icons.cloud_upload_outlined), isTrue);
    expect(find.text('Preparando la imagen'), findsNothing);

    timeline.report(ScanStage.processing);
    await next(tester);
    expect(find.text('Procesando el resultado'), findsOneWidget);
    expect(hasIcon(Icons.fact_check_outlined), isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testDialog('shows a check when everything is done', (tester) async {
    await open(tester);

    timeline.complete();
    await next(tester);

    expect(find.text('Todo listo'), findsOneWidget);
    expect(hasIcon(Icons.check_rounded), isTrue);

    await next(tester);
  });

  group('when a stage fails', () {
    const titles = {
      ScanStage.preparing: 'No se pudo preparar la imagen',
      ScanStage.sending: 'No se pudo completar el envío',
      ScanStage.processing: 'No se pudo procesar el resultado',
    };

    for (final entry in titles.entries) {
      testDialog('explains the ${entry.key.name} failure', (tester) async {
        await open(tester);
        if (entry.key != ScanStage.preparing) timeline.report(entry.key);

        timeline.fail('Servicio no disponible.');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Servicio no disponible.'), findsOneWidget);
        expect(hasIcon(Icons.error_outline_rounded), isTrue);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }

    testDialog('closes with the Cerrar button', (tester) async {
      await open(tester);
      timeline.fail('Servicio no disponible.');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Servicio no disponible.'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });

  testDialog('has no way out while it is running', (tester) async {
    await open(tester);

    expect(find.text('Cerrar'), findsNothing);

    // Tapping the barrier does nothing.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Preparando la imagen'), findsOneWidget);
  });
}
