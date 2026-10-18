import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/diagnostics/error_reporter.dart';

void main() {
  group('NoopErrorReporter', () {
    test('accepts a report without doing anything or throwing', () async {
      const reporter = NoopErrorReporter();

      await expectLater(
        reporter.recordError(
          Exception('boom'),
          StackTrace.current,
          reason: 'test',
        ),
        completes,
      );
    });

    test('accepts a fatal report without doing anything or throwing', () async {
      const reporter = NoopErrorReporter();

      await expectLater(
        reporter.recordError(
          Exception('boom'),
          StackTrace.current,
          fatal: true,
        ),
        completes,
      );
    });

    test('is usable as an ErrorReporter', () {
      const ErrorReporter reporter = NoopErrorReporter();

      expect(reporter, isA<ErrorReporter>());
    });
  });
}
