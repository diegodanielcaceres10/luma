import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/diagnostics/global_error_handlers.dart';

import '../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeErrorReporter reporter;
  late FlutterExceptionHandler? originalFlutterHandler;
  late ErrorCallback? originalPlatformHandler;

  setUp(() {
    reporter = FakeErrorReporter();
    originalFlutterHandler = FlutterError.onError;
    originalPlatformHandler = PlatformDispatcher.instance.onError;
    // The test binding's own handler would turn the errors raised here into
    // test failures.
    FlutterError.onError = (_) {};
    PlatformDispatcher.instance.onError = null;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterHandler;
    PlatformDispatcher.instance.onError = originalPlatformHandler;
  });

  FlutterErrorDetails frameworkError(Object error) =>
      FlutterErrorDetails(exception: error, stack: StackTrace.current);

  group('installGlobalErrorHandlers for framework errors', () {
    test('reports the error as fatal', () {
      installGlobalErrorHandlers(reporter);

      FlutterError.onError!(frameworkError(StateError('boom')));

      final report = reporter.reports.single;
      expect(report.fatal, isTrue);
      expect(report.reason, 'Flutter framework error');
      expect(report.error, isA<UnhandledAppError>());
    });

    test('still calls the handler that was installed before', () {
      final previousCalls = <FlutterErrorDetails>[];
      FlutterError.onError = previousCalls.add;
      installGlobalErrorHandlers(reporter);

      final details = frameworkError(StateError('boom'));
      FlutterError.onError!(details);

      expect(previousCalls, [details]);
    });

    test('reports even when there was no handler before', () {
      FlutterError.onError = null;
      installGlobalErrorHandlers(reporter);

      FlutterError.onError!(frameworkError(StateError('boom')));

      expect(reporter.reports, hasLength(1));
    });
  });

  group('installGlobalErrorHandlers for uncaught asynchronous errors', () {
    test('reports the error as fatal', () {
      installGlobalErrorHandlers(reporter);

      PlatformDispatcher.instance.onError!(
        StateError('boom'),
        StackTrace.current,
      );

      final report = reporter.reports.single;
      expect(report.fatal, isTrue);
      expect(report.reason, 'Uncaught asynchronous error');
      expect(report.error, isA<UnhandledAppError>());
    });

    test('leaves the error unhandled when nothing handled it before', () {
      installGlobalErrorHandlers(reporter);

      final handled = PlatformDispatcher.instance.onError!(
        StateError('boom'),
        StackTrace.current,
      );

      expect(handled, isFalse);
    });

    test('returns what the handler installed before returned', () {
      PlatformDispatcher.instance.onError = (error, stack) => true;
      installGlobalErrorHandlers(reporter);

      final handled = PlatformDispatcher.instance.onError!(
        StateError('boom'),
        StackTrace.current,
      );

      expect(handled, isTrue);
      expect(reporter.reports, hasLength(1));
    });
  });

  group('UnhandledAppError', () {
    test('names the type and the message of the cause', () {
      final error = UnhandledAppError(StateError('Bad state: no session'));

      expect(
        error.toString(),
        'UnhandledAppError: StateError: Bad state: no session',
      );
    });

    test('keeps ids and email addresses out of the report', () {
      const id = '123e4567-e89b-12d3-a456-426614174000';
      final error = UnhandledAppError(
        StateError('Account $id of user.name@example.com not found'),
      );

      final text = error.toString();

      expect(text, isNot(contains(id)));
      expect(text, isNot(contains('user.name@example.com')));
      expect(text, contains('<id>'));
      expect(text, contains('<email>'));
    });

    test('is an Exception', () {
      expect(UnhandledAppError('boom'), isA<Exception>());
    });
  });
}
