import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.signInWithGoogle();
    } catch (error) {
      _errorMessage = 'Unable to sign in with Google.';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
