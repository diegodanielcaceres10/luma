import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/ai/scan_progress_timeline.dart';
import 'package:luma/core/ai/scan_stage.dart';

void main() {
  const second = Duration(seconds: 1);

  late ScanProgressTimeline timeline;
  var notifications = 0;

  setUp(() {
    notifications = 0;
    timeline = ScanProgressTimeline()..addListener(() => notifications++);
  });

  tearDown(() => timeline.dispose());

  // A widget test must end without pending timers: the timeline holds one for
  // the stage being shown, so it is released when the body is done.
  void testTimeline(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      await body(tester);
      timeline.dispose();
    });
  }

  ScanStage stage() => timeline.state.stage;
  ScanProgressPhase phase() => timeline.state.phase;

  test('dispose can be called twice', () {
    timeline.dispose();

    expect(timeline.dispose, returnsNormally);
  });

  test('starts on the first stage', () {
    expect(stage(), ScanStage.preparing);
    expect(phase(), ScanProgressPhase.running);
    expect(timeline.state.message, isNull);
  });

  testTimeline('keeps each stage for at least the stage duration',
      (tester) async {
    timeline.report(ScanStage.sending);
    timeline.report(ScanStage.processing);

    // Nothing moves while the first stage is still being held.
    expect(stage(), ScanStage.preparing);
    await tester.pump(const Duration(milliseconds: 999));
    expect(stage(), ScanStage.preparing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(stage(), ScanStage.sending);

    await tester.pump(const Duration(milliseconds: 999));
    expect(stage(), ScanStage.sending);

    await tester.pump(const Duration(milliseconds: 1));
    expect(stage(), ScanStage.processing);
  });

  testTimeline('does not make a slow stage any longer', (tester) async {
    // The request takes 4 s: the stage is shown as long as it lasts.
    await tester.pump(second);
    timeline.report(ScanStage.sending);
    expect(stage(), ScanStage.sending);

    await tester.pump(const Duration(seconds: 4));
    timeline.report(ScanStage.processing);

    // The held time was already over, so it changes right away.
    expect(stage(), ScanStage.processing);
  });

  testTimeline('ignores a stage that is already the last one', (tester) async {
    timeline.report(ScanStage.preparing);
    timeline.report(ScanStage.sending);
    timeline.report(ScanStage.sending);
    await tester.pump(second);
    expect(stage(), ScanStage.sending);
    final before = notifications;

    await tester.pump(second);

    expect(stage(), ScanStage.sending);
    expect(notifications, before);
  });

  testTimeline('notifies on every change', (tester) async {
    timeline.report(ScanStage.sending);
    await tester.pump(second);

    expect(notifications, 1);
  });

  group('complete', () {
    testTimeline('shows done after the pending stages and holds it',
        (tester) async {
      timeline.report(ScanStage.sending);
      timeline.report(ScanStage.processing);
      var finished = false;
      timeline.complete().then((_) => finished = true);

      await tester.pump(second);
      expect(stage(), ScanStage.sending);
      await tester.pump(second);
      expect(stage(), ScanStage.processing);
      expect(phase(), ScanProgressPhase.running);

      await tester.pump(second);
      expect(phase(), ScanProgressPhase.done);
      expect(finished, isFalse);

      // Done stays visible for a full stage before the future completes.
      await tester.pump(second);
      expect(finished, isTrue);
    });

    testTimeline('shows done right away when the last stage was held enough',
        (tester) async {
      await tester.pump(second);
      var finished = false;
      timeline.complete().then((_) => finished = true);

      expect(phase(), ScanProgressPhase.done);
      expect(finished, isFalse);

      await tester.pump(second);
      expect(finished, isTrue);
    });

    testTimeline('keeps the last stage on done', (tester) async {
      timeline.report(ScanStage.processing);
      timeline.complete();
      await tester.pump(second);
      await tester.pump(second);

      expect(phase(), ScanProgressPhase.done);
      expect(stage(), ScanStage.processing);
    });
  });

  group('fail', () {
    testTimeline('shows the failure right away with its message',
        (tester) async {
      timeline.fail('Servicio no disponible.');

      expect(phase(), ScanProgressPhase.failed);
      expect(timeline.state.message, 'Servicio no disponible.');
      expect(notifications, 1);
    });

    testTimeline('fails in the last stage that was reported, shown or not',
        (tester) async {
      timeline.report(ScanStage.sending);
      timeline.report(ScanStage.processing);
      timeline.fail('boom');

      expect(stage(), ScanStage.processing);
    });

    testTimeline('drops the stages that were still waiting', (tester) async {
      timeline.report(ScanStage.sending);
      timeline.fail('boom');
      await tester.pump(const Duration(seconds: 5));

      expect(phase(), ScanProgressPhase.failed);
      expect(stage(), ScanStage.sending);
    });

    testTimeline('ignores later reports', (tester) async {
      timeline.fail('boom');
      timeline.report(ScanStage.processing);
      await tester.pump(second);

      expect(stage(), ScanStage.preparing);
      expect(phase(), ScanProgressPhase.failed);
    });
  });

  testTimeline('a custom stage duration is respected', (tester) async {
    final quick = ScanProgressTimeline(
      stageDuration: const Duration(milliseconds: 200),
    );

    quick.report(ScanStage.sending);
    await tester.pump(const Duration(milliseconds: 200));

    expect(quick.state.stage, ScanStage.sending);
    quick.dispose();
  });
}
