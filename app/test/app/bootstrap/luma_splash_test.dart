import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:luma/app/bootstrap/luma_splash.dart';
import 'package:luma/core/widgets/luma_logo.dart';

/// Serves every asset except the Lottie file, which fails to load.
class _LottieFailingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.endsWith('.json')) {
      return Future<ByteData>.error(FlutterError('broken lottie asset'));
    }
    return rootBundle.load(key);
  }
}

void main() {
  const canvasKey = ValueKey('luma-splash-canvas');

  late ValueNotifier<bool> ready;
  late int finished;

  setUp(() {
    ready = ValueNotifier<bool>(false);
    finished = 0;
  });

  tearDown(() => ready.dispose());

  Future<void> pumpSplash(
    WidgetTester tester, {
    AssetBundle? bundle,
    bool disableAnimations = false,
  }) async {
    Widget app = MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: ready,
        builder: (_, value, __) =>
            LumaSplash(ready: value, onFinished: () => finished++),
      ),
    );
    if (bundle != null) {
      app = DefaultAssetBundle(bundle: bundle, child: app);
    }
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: app,
      ),
    );
  }

  // The Lottie asset loads asynchronously, outside the fake clock.
  Future<void> letAssetsLoad(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  // The loop never settles, so time is advanced by hand, never pumpAndSettle.
  // It goes in 100 ms frames: the start delay timer and each animation phase
  // anchor on the first frame after they fire, so a single big jump would make
  // the exact finishing instant depend on frame granularity.
  Future<void> elapse(WidgetTester tester, Duration time) async {
    const step = Duration(milliseconds: 100);
    var left = time;
    while (left > Duration.zero) {
      final frame = left < step ? left : step;
      await tester.pump(frame);
      left -= frame;
    }
  }

  // Earliest instant at which onFinished can fire when ready is true before
  // the first loop ends: start delay, one loop and the outro. Every phase can
  // start up to one frame late, hence the margins used by the tests.
  final minimumTotal = LumaSplash.startDelay +
      LumaSplash.loopDuration +
      LumaSplash.outroDuration;
  const frameMargin = Duration(milliseconds: 100);
  const lateMargin = Duration(milliseconds: 600);

  testWidgets('draws the leaf 96 px high', (tester) async {
    await pumpSplash(tester);
    await letAssetsLoad(tester);

    // The Lottie canvas keeps a 32 px margin on each side of 512, so the leaf
    // is 87.5% of the canvas height.
    expect(
      tester.getSize(find.byKey(canvasKey)).height,
      closeTo(96 / 0.875, 0.01),
    );
  });

  testWidgets('does not finish while ready is false', (tester) async {
    await pumpSplash(tester);
    await letAssetsLoad(tester);

    await elapse(tester, const Duration(seconds: 10));

    expect(finished, 0);
  });

  testWidgets(
      'finishes once after the current loop and the outro when ready turns '
      'true', (tester) async {
    await pumpSplash(tester);
    await letAssetsLoad(tester);

    await elapse(tester, const Duration(milliseconds: 500));
    ready.value = true;
    await tester.pump();

    // The loop is still running: ready does not cut it short.
    const sofar = Duration(milliseconds: 2500);
    await elapse(tester, const Duration(milliseconds: 2000));
    expect(finished, 0);

    // Stop just short of the earliest possible finish.
    await elapse(tester, minimumTotal - frameMargin - sofar);
    expect(finished, 0);

    await elapse(tester, frameMargin + lateMargin);
    expect(finished, 1);

    await elapse(tester, const Duration(seconds: 5));
    expect(finished, 1);
  });

  testWidgets('finishes once even if ready is true from the first frame',
      (tester) async {
    ready.value = true;
    await pumpSplash(tester);
    await letAssetsLoad(tester);

    // Start delay, loop and outro all have to play before it finishes.
    await elapse(tester, minimumTotal - frameMargin);
    expect(finished, 0);

    await elapse(tester, frameMargin + lateMargin);
    expect(finished, 1);

    await elapse(tester, const Duration(seconds: 5));
    expect(finished, 1);
  });

  testWidgets('falls back to the static logo when the asset fails to load',
      (tester) async {
    ready.value = true;
    await pumpSplash(tester, bundle: _LottieFailingBundle());
    await letAssetsLoad(tester);
    await tester.pump();

    expect(find.byType(LumaLogo), findsOneWidget);
    expect(finished, 1);

    // The loop timer must not report a second time.
    await elapse(tester, const Duration(seconds: 5));
    expect(finished, 1);
  });

  testWidgets('skips the animation when animations are disabled',
      (tester) async {
    await pumpSplash(tester, disableAnimations: true);
    await tester.pump();

    expect(find.byType(Lottie), findsNothing);
    expect(find.byType(LumaLogo), findsOneWidget);
    expect(finished, 0);

    ready.value = true;
    await tester.pump();
    await tester.pump();

    expect(finished, 1);
  });

  testWidgets('finishes right away when animations are disabled and ready',
      (tester) async {
    ready.value = true;
    await pumpSplash(tester, disableAnimations: true);
    await tester.pump();

    expect(finished, 1);
  });
}
