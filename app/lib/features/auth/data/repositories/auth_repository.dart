import 'package:supabase_flutter/supabase_flutter.dart';
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

  bool get isAuthenticated => _service.currentSession != null;

  User? get currentUser => _service.currentUser;

  Stream<AuthState> get authStateChanges => _service.authStateChanges;
}
