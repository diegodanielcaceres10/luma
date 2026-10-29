import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/data/services/push_token_registrar.dart';

import '../../../helpers/fakes.dart';

void main() {
  late List<String> calls;
  late FakePushMessagingService messaging;
  late FakeDeviceTokenRepository tokens;
  late FakeErrorReporter reporter;
  late PushTokenRegistrar registrar;

  setUp(() {
    calls = [];
    messaging = FakePushMessagingService(calls);
    tokens = FakeDeviceTokenRepository(calls);
    reporter = FakeErrorReporter();
    registrar = PushTokenRegistrar(
      messaging: messaging,
      tokens: tokens,
      reporter: () async => reporter,
    );
  });

  /// A registrar that gives up on a call after a few milliseconds.
  PushTokenRegistrar impatientRegistrar() => PushTokenRegistrar(
        messaging: messaging,
        tokens: tokens,
        reporter: () async => reporter,
        timeout: const Duration(milliseconds: 10),
      );

  tearDown(() => registrar.dispose());

  group('PushTokenRegistrar', () {
    test('start registers the current token for android', () async {
      await registrar.start();

      expect(calls, ['getToken', 'register:token-a:android']);
    });

    test('a token refresh registers the new token', () async {
      await registrar.start();

      messaging.emitRefresh('token-b');
      await pumpEventQueue();

      expect(calls.last, 'register:token-b:android');
    });

    test('start twice listens only once', () async {
      await registrar.start();
      await registrar.start();
      calls.clear();

      messaging.emitRefresh('token-b');
      await pumpEventQueue();

      expect(calls, ['register:token-b:android']);
    });

    test('an unsupported platform does nothing', () async {
      messaging.isSupported = false;

      await registrar.start();
      await registrar.stopAndRemove();
      await registrar.release();

      expect(calls, isEmpty);
    });

    test('stopAndRemove deletes the row, then invalidates the token',
        () async {
      await registrar.start();
      calls.clear();

      await registrar.stopAndRemove();

      expect(calls, ['unregister:token-a', 'deleteToken']);

      calls.clear();
      messaging.emitRefresh('token-b');
      await pumpEventQueue();
      expect(calls, isEmpty);
    });

    test('stopAndRemove deletes the refreshed token', () async {
      await registrar.start();
      messaging.emitRefresh('token-b');
      await pumpEventQueue();
      calls.clear();

      await registrar.stopAndRemove();

      expect(calls, ['unregister:token-b', 'deleteToken']);
    });

    test('release only invalidates the token', () async {
      await registrar.start();
      calls.clear();

      await registrar.release();

      expect(calls, ['deleteToken']);

      calls.clear();
      messaging.emitRefresh('token-b');
      await pumpEventQueue();
      expect(calls, isEmpty);
    });

    test('dispose stops listening', () async {
      await registrar.start();
      calls.clear();

      registrar.dispose();
      messaging.emitRefresh('token-b');
      await pumpEventQueue();

      expect(calls, isEmpty);
    });

    test(
        'a failing getToken is reported, not thrown, and a later refresh '
        'still registers', () async {
      messaging.getTokenError = StateError('no token');

      await registrar.start();

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.reason, 'Push token registration');

      messaging.getTokenError = null;
      messaging.emitRefresh('token-b');
      await pumpEventQueue();
      expect(calls, contains('register:token-b:android'));
    });

    test('a failing register is reported and does not throw', () async {
      tokens.registerError = StateError('offline');

      await registrar.start();

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.reason, 'Push token registration');
    });

    test('a failing unregister still invalidates the token', () async {
      await registrar.start();
      tokens.unregisterError = StateError('offline');
      calls.clear();

      await registrar.stopAndRemove();

      expect(calls, ['unregister:token-a', 'deleteToken']);
      expect(reporter.reports, hasLength(1));
    });

    test('without permission nothing is requested or registered', () async {
      messaging.permissionGranted = false;

      await registrar.start();

      expect(calls, isEmpty);
      expect(reporter.reports, isEmpty);
    });

    test('a failing permission request is reported and nothing is registered',
        () async {
      messaging.permissionError = StateError('prompt failed');

      await registrar.start();

      expect(calls, isEmpty);
      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.reason, 'Push token registration');
    });

    test('the time the user takes to answer the permission is not limited',
        () async {
      messaging.holdPermission = Completer<void>();
      final impatient = impatientRegistrar();

      final started = impatient.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      messaging.holdPermission!.complete();
      await started;

      expect(calls, ['getToken', 'register:token-a:android']);
      expect(reporter.reports, isEmpty);
      impatient.dispose();
    });

    test('a hanging getToken times out and is reported', () async {
      messaging.holdGetToken = Completer<String?>();
      final impatient = impatientRegistrar();

      await impatient.start();

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.error, isA<TimeoutException>());
      impatient.dispose();
    });

    test('a hanging register times out, is reported and does not block',
        () async {
      tokens.holdRegister = Completer<void>();
      final impatient = impatientRegistrar();

      await impatient.start();
      tokens.holdRegister = null;
      calls.clear();
      await impatient.stopAndRemove();

      expect(reporter.reports.first.error, isA<TimeoutException>());
      expect(calls, ['unregister:token-a', 'deleteToken']);
      impatient.dispose();
    });
  });
}
