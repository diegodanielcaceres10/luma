import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;

  AuthRepository(this._service);

  Future<bool> signInWithGoogle() {
    return _service.signInWithGoogle();
  }

  Future<void> signOut() {
    return _service.signOut();
  }

  bool get isAuthenticated {
    return _service.currentSession != null;
  }

  Stream get authStateChanges {
    return _service.authStateChanges;
  }
}
