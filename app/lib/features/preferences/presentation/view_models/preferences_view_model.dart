import 'package:flutter/foundation.dart';

import '../../data/models/app_preferences.dart';
import '../../data/repositories/preferences_repository.dart';

class PreferencesViewModel extends ChangeNotifier {
  final PreferencesRepository _repository;

  PreferencesViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  AppPreferences _preferences = const AppPreferences.defaults();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppPreferences get preferences => _preferences;

  Future<void> loadPreferences() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _preferences = await _repository.load();
    } catch (error) {
      _errorMessage = 'No se pudieron cargar las preferencias.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCurrencyCode(String value) => _applyAndPersist(
        (prefs) => prefs.copyWith(currencyCode: value),
        () => _repository.setCurrencyCode(value),
      );

  Future<void> setDarkThemeEnabled(bool value) => _applyAndPersist(
        (prefs) => prefs.copyWith(darkThemeEnabled: value),
        () => _repository.setDarkThemeEnabled(value),
      );

  Future<void> setNotificationsEnabled(bool value) => _applyAndPersist(
        (prefs) => prefs.copyWith(notificationsEnabled: value),
        () => _repository.setNotificationsEnabled(value),
      );

  Future<void> setInvoiceReminderDaysAhead(int value) => _applyAndPersist(
        (prefs) => prefs.copyWith(invoiceReminderDaysAhead: value),
        () => _repository.setInvoiceReminderDaysAhead(value),
      );

  Future<void> setBiometricLockEnabled(bool value) => _applyAndPersist(
        (prefs) => prefs.copyWith(biometricLockEnabled: value),
        () => _repository.setBiometricLockEnabled(value),
      );

  /// Actualiza el estado en memoria al toque (para que el control reaccione
  /// al instante) y recién después persiste. Si falla el guardado local
  /// (poco común: sin espacio, storage no disponible, etc.), se revierte el
  /// valor en memoria y se informa el error.
  Future<void> _applyAndPersist(
    AppPreferences Function(AppPreferences current) apply,
    Future<void> Function() persist,
  ) async {
    final previous = _preferences;
    _preferences = apply(_preferences);
    _errorMessage = null;
    notifyListeners();

    try {
      await persist();
    } catch (error) {
      _preferences = previous;
      _errorMessage = 'No se pudo guardar la preferencia.';
      notifyListeners();
    }
  }
}
