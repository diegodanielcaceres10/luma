import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/notifications/data/services/notification_check_failure.dart';

void main() {
  group('NotificationCheckFailure', () {
    test('names the check and the type and message of the cause', () {
      final failure = NotificationCheckFailure(
        check: 'Vencimientos',
        cause: PlatformException(
          code: 'invalid_large_icon',
          message: 'The resource ic_launcher could not be found.',
        ),
      );

      final text = failure.toString();

      expect(text, startsWith('NotificationCheckFailure(Vencimientos): '));
      expect(text, contains('PlatformException'));
      expect(text, contains('invalid_large_icon'));
      expect(text, contains('ic_launcher could not be found'));
    });

    test('keeps ids out of the report', () {
      const id = '123e4567-e89b-12d3-a456-426614174000';
      final failure = NotificationCheckFailure(
        check: 'Cuentas sin actualizar',
        cause: StateError('Account $id not found'),
      );

      final text = failure.toString();

      expect(text, isNot(contains(id)));
      expect(text, contains('<id>'));
    });

    test('is an Exception', () {
      const failure = NotificationCheckFailure(check: 'x', cause: 'boom');

      expect(failure, isA<Exception>());
    });
  });
}
