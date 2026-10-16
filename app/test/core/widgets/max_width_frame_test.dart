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

  testWidgets('paints the side decoration behind the frame', (tester) async {
    await setViewport(tester, const Size(1200, 800));
    const gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF123456), Color(0xFF654321)],
    );
    const decoration = BoxDecoration(gradient: gradient);

    await tester.pumpWidget(
      _host(
        const MaxWidthFrame(
          maxWidth: 480,
          sideDecoration: decoration,
          child: SizedBox.expand(),
        ),
      ),
    );

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MaxWidthFrame),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(box.decoration, decoration);
  });

  testWidgets('uses a 720 px default maximum width', (tester) async {
    await setViewport(tester, const Size(1920, 1000));

    await tester.pumpWidget(
      _host(
        const MaxWidthFrame(child: SizedBox.expand(key: Key('content'))),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('content'))).width, 720);
  });
}
