import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/transactions/presentation/widgets/entry_mode_card.dart';

void main() {
  const scanKey = Key('scan');
  const manualKey = Key('manual');

  Future<void> pumpOptions(
    WidgetTester tester, {
    required double width,
    VoidCallback? onScan,
    VoidCallback? onManual,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: EntryModeOptions(
                  cards: [
                    EntryModeCard(
                      key: scanKey,
                      icon: Icons.document_scanner_rounded,
                      title: 'Escanear ticket',
                      subtitle: 'Tomá una foto del ticket y extraemos la '
                          'información automáticamente.',
                      highlighted: true,
                      onTap: onScan,
                    ),
                    EntryModeCard(
                      key: manualKey,
                      icon: Icons.article_outlined,
                      title: 'Completar manualmente',
                      subtitle: 'Ingresá los datos del movimiento uno por uno.',
                      onTap: onManual,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('puts the cards side by side with equal size when there is room',
      (tester) async {
    await pumpOptions(tester, width: 1200);

    final scan = tester.getRect(find.byKey(scanKey));
    final manual = tester.getRect(find.byKey(manualKey));

    expect(scan.top, manual.top);
    expect(scan.height, manual.height);
    expect(scan.width, manual.width);
    expect(scan.right, lessThan(manual.left));
  });

  testWidgets('stacks the cards on narrow screens', (tester) async {
    await pumpOptions(tester, width: 400);

    final scan = tester.getRect(find.byKey(scanKey));
    final manual = tester.getRect(find.byKey(manualKey));

    expect(scan.left, manual.left);
    expect(scan.width, manual.width);
    expect(scan.bottom, lessThan(manual.top));
  });

  testWidgets('keeps both cards tappable in the side-by-side layout',
      (tester) async {
    var scanTaps = 0;
    var manualTaps = 0;
    await pumpOptions(
      tester,
      width: 1200,
      onScan: () => scanTaps++,
      onManual: () => manualTaps++,
    );

    await tester.tap(find.text('Escanear ticket'));
    await tester.tap(find.text('Completar manualmente'));

    expect(scanTaps, 1);
    expect(manualTaps, 1);
  });

  testWidgets('shows title, description and chevron in the vertical layout',
      (tester) async {
    await pumpOptions(tester, width: 1200);

    expect(find.text('Escanear ticket'), findsOneWidget);
    expect(find.textContaining('Tomá una foto'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
  });
}
