import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription _authSubscription;

  AuthViewModel(this._repository) {
    _isAuthenticated = _repository.isAuthenticated;
    _authSubscription = _repository.authStateChanges.listen(_onAuthStateChange);
  }

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Completer used to resolve the sign-in once the OAuth callback arrives.
  Completer<AuthState>? _oauthCompleter;

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

  String get initials {
    final parts =
        displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  void _onAuthStateChange(AuthState state) {
    _isAuthenticated = _repository.isAuthenticated;

    // If we are waiting for an OAuth callback, resolve the completer.
    if (_oauthCompleter != null && !_oauthCompleter!.isCompleted) {
      _oauthCompleter!.complete(state);
    }

    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    _setLoading(true);
    _errorMessage = null;

    _oauthCompleter = Completer<AuthState>();

    try {
      // Launch the external Google sign-in flow. This returns immediately;
      // the actual session arrives via the auth state stream.
      await _repository.signInWithGoogle();

      // Wait up to 2 minutes for the OAuth callback to return.
      await _oauthCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            throw TimeoutException('Login cancelled or timed out.'),
      );
    } on TimeoutException {
      _errorMessage = 'Inicio de sesión cancelado.';
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Error desconocido. No se pudo autenticar.';
      notifyListeners();
    } finally {
      _oauthCompleter = null;
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
