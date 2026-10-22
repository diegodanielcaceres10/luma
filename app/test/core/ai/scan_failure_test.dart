import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/ai/scan_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  ScanFailure fromResponse(int status, Object? body) =>
      ScanFailure.fromResponse(
        function: 'gemini-image-reader',
        status: status,
        body: body,
      );

  group('ScanFailure.fromResponse', () {
    test('maps each code sent by the Edge Function to its kind', () {
      expect(
        fromResponse(429, {'error': 'x', 'code': 'quota'}).kind,
        ScanFailureKind.quota,
      );
      expect(
        fromResponse(500, {'error': 'x', 'code': 'config'}).kind,
        ScanFailureKind.config,
      );
      expect(
        fromResponse(502, {'error': 'x', 'code': 'parse'}).kind,
        ScanFailureKind.parse,
      );
      expect(
        fromResponse(502, {'error': 'x', 'code': 'upstream'}).kind,
        ScanFailureKind.upstream,
      );
    });

    test('trusts the code over the status', () {
      expect(
        fromResponse(502, {'code': 'quota'}).kind,
        ScanFailureKind.quota,
      );
    });

    test('keeps the status of the response', () {
      expect(fromResponse(502, {'code': 'parse'}).status, 502);
    });

    test('falls back to the status when the code is missing or unknown', () {
      expect(fromResponse(429, {'error': 'x'}).kind, ScanFailureKind.quota);
      expect(
        fromResponse(503, {'code': 'something-new'}).kind,
        ScanFailureKind.upstream,
      );
      expect(fromResponse(500, null).kind, ScanFailureKind.upstream);
    });

    test('is unavailable for other client errors without a code', () {
      expect(
        fromResponse(400, {'error': 'x'}).kind,
        ScanFailureKind.unavailable,
      );
      expect(
        fromResponse(413, 'text body').kind,
        ScanFailureKind.unavailable,
      );
    });
  });

  group('ScanFailure.fromError', () {
    test('reads the status and body of a failed function call', () {
      final failure = ScanFailure.fromError(
        'gemini-statement-reader',
        const FunctionException(
          status: 502,
          details: {'error': 'x', 'code': 'parse'},
        ),
      );

      expect(failure.function, 'gemini-statement-reader');
      expect(failure.kind, ScanFailureKind.parse);
      expect(failure.status, 502);
    });

    test('keeps a failure that is already classified', () {
      const original = ScanFailure(
        function: 'gemini-image-reader',
        kind: ScanFailureKind.parse,
      );

      expect(ScanFailure.fromError('other', original), same(original));
    });

    test('treats any other error as unavailable, with no status', () {
      final failure = ScanFailure.fromError(
        'gemini-image-reader',
        Exception('Failed host lookup'),
      );

      expect(failure.kind, ScanFailureKind.unavailable);
      expect(failure.status, isNull);
    });
  });

  group('ScanFailure messages', () {
    test('every kind has its own message for the user', () {
      final messages = {
        for (final kind in ScanFailureKind.values)
          kind: ScanFailure(function: 'f', kind: kind).userMessage,
      };

      expect(messages.values.toSet(), hasLength(ScanFailureKind.values.length));
      expect(messages.values.every((m) => m.isNotEmpty), isTrue);
    });

    test('an unavailable service uses the generic message', () {
      const failure = ScanFailure(
        function: 'f',
        kind: ScanFailureKind.unavailable,
      );

      expect(failure.userMessage, scanUnavailableMessage);
    });
  });

  group('ScanFailure.shouldReport', () {
    test('reports what points to a problem of the app or the service', () {
      for (final kind in [
        ScanFailureKind.config,
        ScanFailureKind.parse,
        ScanFailureKind.upstream,
      ]) {
        expect(ScanFailure(function: 'f', kind: kind).shouldReport, isTrue);
      }
    });

    test('does not report an expected quota limit or a lost connection', () {
      for (final kind in [
        ScanFailureKind.quota,
        ScanFailureKind.unavailable,
      ]) {
        expect(ScanFailure(function: 'f', kind: kind).shouldReport, isFalse);
      }
    });
  });

  group('ScanFailure.toString', () {
    test('names the function, the kind and the status', () {
      const failure = ScanFailure(
        function: 'gemini-image-reader',
        kind: ScanFailureKind.parse,
        status: 502,
      );

      expect(
        failure.toString(),
        'ScanFailure(gemini-image-reader): parse (HTTP 502)',
      );
    });

    test('leaves the status out when there was no response', () {
      const failure = ScanFailure(
        function: 'gemini-image-reader',
        kind: ScanFailureKind.unavailable,
      );

      expect(
        failure.toString(),
        'ScanFailure(gemini-image-reader): unavailable',
      );
    });

    test('never includes the body of the response', () {
      final failure = fromResponse(502, {
        'error': 'Total 1234.56 at Super Mercado',
        'code': 'parse',
      });

      expect(failure.toString(), isNot(contains('1234.56')));
      expect(failure.toString(), isNot(contains('Super Mercado')));
    });

    test('is an Exception', () {
      expect(
        const ScanFailure(function: 'f', kind: ScanFailureKind.config),
        isA<Exception>(),
      );
    });
  });
}
