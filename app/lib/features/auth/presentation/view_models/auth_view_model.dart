import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.signInWithGoogle();
      _isAuthenticated = _repository.isAuthenticated;
      notifyListeners();
    } on GoogleSignInException catch (error, stackTrace) {
      debugPrint(
        'Google sign-in failed: code=${error.code.name} '
        'description=${error.description} details=${error.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _googleSignInErrorMessage(error);
      notifyListeners();
    } on AuthException catch (error, stackTrace) {
      debugPrint('Supabase Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = 'No se pudo iniciar sesión con Google.';
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Unexpected Google sign-in error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = 'Error desconocido. No se pudo autenticar.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  String _googleSignInErrorMessage(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Inicio de sesión cancelado.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Configuración de Google incompleta. Revisa package, SHA-1 y Web Client ID.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Play Services no está disponible o está mal configurado.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'No se pudo mostrar el inicio de sesión de Google.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Inicio de sesión interrumpido. Intenta nuevamente.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'La cuenta seleccionada no coincide con la sesión actual.';
      case GoogleSignInExceptionCode.unknownError:
        return 'No se pudo iniciar sesión con Google.';
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
