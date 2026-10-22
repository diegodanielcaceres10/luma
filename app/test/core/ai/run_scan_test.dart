import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/ai/run_scan.dart';
import 'package:luma/core/ai/scan_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeErrorReporter reporter;

  setUp(() => reporter = FakeErrorReporter());

  Future<T> run<T>(Future<T> Function() action) => runScan<T>(
        function: 'gemini-image-reader',
        reason: 'Receipt scan',
        reporter: () async => reporter,
        action: action,
      );

  group('runScan', () {
    test('returns the result and reports nothing when the scan works',
        () async {
      final result = await run(() async => 'scanned');

      expect(result, 'scanned');
      expect(reporter.reports, isEmpty);
    });

    test('turns a failed function call into a ScanFailure', () async {
      await expectLater(
        run<String>(
          () async => throw const FunctionException(
            status: 429,
            details: {'error': 'x', 'code': 'quota'},
          ),
        ),
        throwsA(
          isA<ScanFailure>()
              .having((f) => f.kind, 'kind', ScanFailureKind.quota)
              .having((f) => f.function, 'function', 'gemini-image-reader'),
        ),
      );
    });

    test('reports a failure that points to a problem, without fatal',
        () async {
      await expectLater(
        run<String>(
          () async => throw const FunctionException(
            status: 502,
            details: {'error': 'x', 'code': 'parse'},
          ),
        ),
        throwsA(isA<ScanFailure>()),
      );

      final report = reporter.reports.single;
      expect(report.error, isA<ScanFailure>());
      expect((report.error as ScanFailure).kind, ScanFailureKind.parse);
      expect(report.reason, 'Receipt scan');
      expect(report.fatal, isFalse);
    });

    test('does not report an expected quota limit', () async {
      await expectLater(
        run<String>(
          () async => throw const FunctionException(
            status: 429,
            details: {'code': 'quota'},
          ),
        ),
        throwsA(isA<ScanFailure>()),
      );

      expect(reporter.reports, isEmpty);
    });

    test('does not report an error without a response, such as no network',
        () async {
      await expectLater(
        run<String>(() async => throw Exception('Failed host lookup')),
        throwsA(
          isA<ScanFailure>().having(
            (f) => f.kind,
            'kind',
            ScanFailureKind.unavailable,
          ),
        ),
      );

      expect(reporter.reports, isEmpty);
    });

    test('reports a failure that the action already classified', () async {
      const failure = ScanFailure(
        function: 'gemini-image-reader',
        kind: ScanFailureKind.parse,
      );

      await expectLater(
        run<String>(() async => throw failure),
        throwsA(same(failure)),
      );

      expect(reporter.reports.single.error, same(failure));
    });

    test('keeps the response body out of the report', () async {
      await expectLater(
        run<String>(
          () async => throw const FunctionException(
            status: 502,
            details: {'error': 'Total 1234.56', 'code': 'upstream'},
          ),
        ),
        throwsA(isA<ScanFailure>()),
      );

      expect(
        reporter.reports.single.error.toString(),
        isNot(contains('1234.56')),
      );
    });

    test('still throws the failure when the reporter cannot start', () async {
      await expectLater(
        runScan<String>(
          function: 'gemini-image-reader',
          reason: 'Receipt scan',
          reporter: () async => throw StateError('no reporter'),
          action: () async => throw const FunctionException(
            status: 502,
            details: {'code': 'parse'},
          ),
        ),
        throwsA(
          isA<ScanFailure>().having(
            (f) => f.kind,
            'kind',
            ScanFailureKind.parse,
          ),
        ),
      );
    });
  });
}
