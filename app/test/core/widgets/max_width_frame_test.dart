import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/widgets/max_width_frame.dart';

Widget _host(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}

void main() {
  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('limits the child width and centers it on wide viewports',
      (tester) async {
    await setViewport(tester, const Size(1920, 1000));

    await tester.pumpWidget(
      _host(
        const MaxWidthFrame(
          maxWidth: 480,
          child: SizedBox.expand(key: Key('content')),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const Key('content')));
    expect(rect.width, 480);
    expect(rect.center.dx, 960);
  });

  testWidgets('does not constrain the child on narrow viewports',
      (tester) async {
    await setViewport(tester, const Size(360, 800));

    await tester.pumpWidget(
      _host(
        const MaxWidthFrame(
          maxWidth: 480,
          child: SizedBox.expand(key: Key('content')),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const Key('content')));
    expect(rect.width, 360);
    expect(rect.left, 0);
  });

  testWidgets('paints the side background behind the frame', (tester) async {
    await setViewport(tester, const Size(1200, 800));
    const sideColor = Color(0xFF123456);

    await tester.pumpWidget(
      _host(
        const MaxWidthFrame(
          maxWidth: 480,
          sideColor: sideColor,
          child: SizedBox.expand(),
        ),
      ),
    );

    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(MaxWidthFrame),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, sideColor);
  });
}
