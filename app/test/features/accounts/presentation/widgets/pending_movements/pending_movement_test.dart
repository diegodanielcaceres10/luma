import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/presentation/widgets/pending_movements/pending_movement.dart';

void main() {
  group('TransferPendingMovement.displayLabel', () {
    test('names the other account when it is known', () {
      expect(
        TransferPendingMovement(
          amount: 10,
          date: DateTime(2026, 8, 1),
          otherAccountId: 'b',
          otherAccountName: 'Cuenta Extra',
        ).displayLabel,
        'Transferencia desde Cuenta Extra',
      );
      expect(
        TransferPendingMovement(
          amount: -10,
          date: DateTime(2026, 8, 1),
          otherAccountId: 'b',
          otherAccountName: 'Cuenta Extra',
        ).displayLabel,
        'Transferencia a Cuenta Extra',
      );
    });

    test('is just "Transferencia" when the other account is unknown', () {
      expect(
        TransferPendingMovement(amount: -10, date: DateTime(2026, 8, 1))
            .displayLabel,
        'Transferencia',
      );
    });
  });
}
