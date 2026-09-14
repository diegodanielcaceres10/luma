import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription _authSubscription;

  AuthViewModel(this._repository) {
    _isAuthenticated = _repository.isAuthenticated;
    _authSubscription = _repository.authStateChanges.listen((_) {
      _isAuthenticated = _repository.isAuthenticated;
      notifyListeners();
    });
  }

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  String? get userId => _repository.currentUser?.id;

  String? get email => _repository.currentUser?.email;

  String get displayName {
    final user = _repository.currentUser;
    final metadata = user?.userMetadata;
    return metadata?['full_name'] ??
        metadata?['name'] ??
        user?.email ??
        'usuario';
  }

  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.signInWithGoogle();
    } catch (error) {
      _errorMessage = 'Unable to sign in with Google.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
