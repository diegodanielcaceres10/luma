import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/theme/app_theme.dart';
import 'package:luma/core/widgets/layout/max_width_frame.dart';

void main() {
  Future<Size> openDialog(WidgetTester tester, Size viewport) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const Dialog(
                  child: SizedBox.expand(key: Key('dialog-content')),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return tester.getSize(find.byKey(const Key('dialog-content')));
  }

  testWidgets('caps the dialog width on wide viewports', (tester) async {
    final size = await openDialog(tester, const Size(1920, 1000));

    expect(size.width, kDialogMaxWidth);
  });

  testWidgets('keeps the default insets on narrow viewports', (tester) async {
    final size = await openDialog(tester, const Size(360, 800));

    // Dialog's default horizontal inset is 40 on each side.
    expect(size.width, 360 - 80);
  });
}
