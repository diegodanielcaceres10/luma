import 'package:flutter_test/flutter_test.dart';
import 'package:luma/core/diagnostics/redact_error_message.dart';

void main() {
  group('redactErrorMessage', () {
    test('keeps a message with nothing to hide as it is', () {
      const message = 'PlatformException(invalid_large_icon, The resource '
          'ic_launcher could not be found., null, null)';

      expect(redactErrorMessage(message), message);
    });

    test('replaces ids', () {
      const id = '123e4567-e89b-12d3-a456-426614174000';

      expect(
        redactErrorMessage('Key (user_id)=($id) is not present'),
        'Key (user_id)=(<id>) is not present',
      );
    });

    test('replaces every id in the message', () {
      const first = '123e4567-e89b-12d3-a456-426614174000';
      const second = 'ABCDEF01-2345-6789-ABCD-EF0123456789';

      expect(redactErrorMessage('$first and $second'), '<id> and <id>');
    });

    test('replaces email addresses', () {
      expect(
        redactErrorMessage('Invalid login for user.name+tag@example.co.uk'),
        'Invalid login for <email>',
      );
    });

    test('cuts a long message at the limit', () {
      final message = 'a' * 400;

      final result = redactErrorMessage(message, maxLength: 300);

      expect(result, '${'a' * 300}…');
    });

    test('does not cut a message that fits', () {
      final message = 'a' * 300;

      expect(redactErrorMessage(message, maxLength: 300), message);
    });
  });
}
