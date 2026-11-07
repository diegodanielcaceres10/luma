import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/auth/data/models/app_preferences.dart';

void main() {
  group('AppPreferences', () {
    test('disables uncontrolled expenses by default', () {
      const preferences = AppPreferences.defaults();

      expect(preferences.uncontrolledExpensesEnabled, isFalse);
    });

    test('updates the uncontrolled expenses preference immutably', () {
      const preferences = AppPreferences.defaults();

      final updated = preferences.copyWith(uncontrolledExpensesEnabled: true);

      expect(updated.uncontrolledExpensesEnabled, isTrue);
      expect(preferences.uncontrolledExpensesEnabled, isFalse);
    });
  });
}
