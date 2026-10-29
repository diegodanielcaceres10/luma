import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/bootstrap/app_bootstrap.dart';
import 'package:luma/app/bootstrap/app_initializer.dart';
import 'package:luma/app/bootstrap/bootstrap_error_view.dart';
import 'package:luma/core/config/app_info.dart';
import 'package:luma/features/home/data/models/version_check_result.dart';

import '../../helpers/fakes.dart';

void main() {
  late List<Completer<void>> backendRuns;
  late VersionCheckResult? version;
  late FakeErrorReporter reporter;
  late int appBuilds;
  late bool lastReady;
  late VoidCallback finishSplash;

  setUp(() {
    backendRuns = [];
    version = null;
    reporter = FakeErrorReporter();
    appBuilds = 0;
    lastReady = false;
    finishSplash = () {};
  });

  VersionCheckResult versionResult(VersionCheckStatus status) {
    return VersionCheckResult(
      status: status,
      message: 'update message',
      installedVersion: '3.1.0',
      currentVersion: '3.1.0',
      minVersion: '3.1.0',
    );
  }

  Widget bootstrap() {
    return AppBootstrap(
      initializer: AppInitializer(
        initializeBackend: () {
          final run = Completer<void>();
          backendRuns.add(run);
          return run.future;
        },
        checkVersion: () async => version,
      ),
      errorReporter: reporter,
      appBuilder: (pendingMessage) {
        appBuilds++;
        return MaterialApp(home: Text('app:${pendingMessage ?? 'none'}'));
      },
      blockedBuilder: (message) => MaterialApp(home: Text('blocked:$message')),
      splashBuilder: (ready, onFinished) {
        lastReady = ready;
        finishSplash = onFinished;
        return const Text('splash', textDirection: TextDirection.ltr);
      },
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('shows the splash while the initializer is pending',
      (tester) async {
    await tester.pumpWidget(bootstrap());

    expect(find.text('splash'), findsOneWidget);
    expect(lastReady, isFalse);
    expect(appBuilds, 0);
  });

  testWidgets(
      'shows the app after the splash finishes, with the pending update '
      'message', (tester) async {
    version = versionResult(VersionCheckStatus.outdatedButUsable);
    await tester.pumpWidget(bootstrap());

    backendRuns.single.complete();
    await tester.pump();

    // Ready, but the splash still plays its outro.
    expect(lastReady, isTrue);
    expect(find.text('splash'), findsOneWidget);
    expect(appBuilds, 0);

    finishSplash();
    await settle(tester);

    expect(find.text('app:update message'), findsOneWidget);
  });

  testWidgets(
      'shows the blocked screen and never builds the app when the result is '
      'blocked', (tester) async {
    version = versionResult(VersionCheckStatus.blocked);
    await tester.pumpWidget(bootstrap());

    backendRuns.single.complete();
    await tester.pump();
    finishSplash();
    await settle(tester);

    expect(find.text('blocked:update message'), findsOneWidget);
    expect(appBuilds, 0);
  });

  testWidgets(
      'shows the error view and reports a non fatal error when the '
      'initializer fails', (tester) async {
    await tester.pumpWidget(bootstrap());

    backendRuns.single.completeError(StateError('backend down'));
    await settle(tester);

    expect(find.text('No pudimos iniciar Luma'), findsOneWidget);
    expect(reporter.reports, hasLength(1));
    expect(reporter.reports.single.fatal, isFalse);
    expect(reporter.reports.single.error, isA<StateError>());
  });

  testWidgets('keeps the app title on the splash and the error view',
      (tester) async {
    await tester.pumpWidget(bootstrap());
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        AppInfo.name);

    backendRuns.single.completeError(StateError('backend down'));
    await settle(tester);

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        AppInfo.name);
  });

  testWidgets(
      'retries from the error view and ends on the app when the second run '
      'succeeds', (tester) async {
    await tester.pumpWidget(bootstrap());
    backendRuns.single.completeError(StateError('backend down'));
    await settle(tester);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(backendRuns, hasLength(2));
    expect(find.text('splash'), findsOneWidget);

    backendRuns.last.complete();
    await tester.pump();
    finishSplash();
    await settle(tester);

    expect(find.text('app:none'), findsOneWidget);
  });

  testWidgets(
      'runs the initializer once when Reintentar is tapped twice '
      'quickly', (tester) async {
    await tester.pumpWidget(bootstrap());
    backendRuns.single.completeError(StateError('backend down'));
    await settle(tester);

    final retry = find.text('Reintentar');
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();

    // The first run plus a single retry.
    expect(backendRuns, hasLength(2));
  });

  testWidgets('ignores a result that arrives after dispose', (tester) async {
    await tester.pumpWidget(bootstrap());

    await tester.pumpWidget(const SizedBox());
    backendRuns.single.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores a failure that arrives after dispose', (tester) async {
    await tester.pumpWidget(bootstrap());

    await tester.pumpWidget(const SizedBox());
    backendRuns.single.completeError(StateError('late failure'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('error view has no overflow at 320x480 with text scale 2.0',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: BootstrapErrorView(onRetry: () {}),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('No pudimos iniciar Luma'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
