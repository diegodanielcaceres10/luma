import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_clock.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../auth/presentation/view_models/preferences_view_model.dart';
import '../../data/services/biometric_service.dart';

/// How long the app may stay in the background before biometrics are
/// requested again upon return. Decision: 30 seconds.
const Duration kAppLockRelockThreshold = Duration(seconds: 30);

/// Failed authentication attempts allowed before forcing sign-out.
/// Decision: 5.
const int kAppLockMaxFailedAttempts = 5;

/// Decides when the app must show the lock screen (a layer on top of the
/// app, see AppLockGate in app.dart) and handles the unlock attempt.
///
/// It does not replace AuthViewModel: the Supabase session (login) and the
/// local lock (biometrics) are independent gates: the router handles the
/// session and AppLockGate the lock. This lock only makes sense if the
/// device supports it AND the user enabled it in Preferences — if either
/// condition is not met,
/// `isLocked` is never activated and the behavior stays as before (no lock
/// of its own, only the operating system lock).
class AppLockViewModel extends ChangeNotifier {
  final BiometricService _biometricService;
  final PreferencesViewModel _preferencesViewModel;
  final AuthViewModel _authViewModel;

  AppLockViewModel({
    required BiometricService biometricService,
    required PreferencesViewModel preferencesViewModel,
    required AuthViewModel authViewModel,
  })  : _biometricService = biometricService,
        _preferencesViewModel = preferencesViewModel,
        _authViewModel = authViewModel;

  bool _isSupported = false;
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _deviceLostSupport = false;
  int _failedAttempts = 0;
  DateTime? _pausedAt;

  /// `true` if the device can authenticate with biometrics or some other OS
  /// lock method. Computed once in [initialize] (it does not change during
  /// the app's lifetime).
  bool get isSupported => _isSupported;

  bool get isLocked => _isLocked;
  bool get isAuthenticating => _isAuthenticating;
  int get failedAttempts => _failedAttempts;

  /// `true` if, when attempting to unlock, it was detected that the device
  /// no longer has any PIN/pattern/password or biometrics configured (for
  /// example, the user removed them after enabling the lock). In that case
  /// it makes no sense to keep requesting biometrics — see [authenticate].
  bool get deviceLostSupport => _deviceLostSupport;

  bool get _lockPreferenceActive {
    return _isSupported && _preferencesViewModel.preferences.biometricLockEnabled;
  }

  /// Called once at app startup (see `app.dart`). Checks the device's
  /// capability and, if applicable, starts locked ("cold" lock).
  Future<void> initialize() async {
    _isSupported = await _biometricService.isSupported();
    if (_lockPreferenceActive) {
      _isLocked = true;
    }
    notifyListeners();
  }

  /// Re-checks whether the device has biometrics or some screen lock
  /// (PIN/pattern/password) configured. The check in [initialize] runs once
  /// at startup and is cached in [isSupported] — if the user sets up a
  /// screen lock *while the app is already open*, without this refresh the
  /// preference would stay disabled until the app restarts. Called, for
  /// example, every time PreferencesScreen is opened.
  Future<void> refreshSupport() async {
    _isSupported = await _biometricService.isSupported();
    notifyListeners();
  }

  /// Called from `didChangeAppLifecycleState` when the app moves to
  /// `paused` (background).
  void onAppPaused() {
    _pausedAt = nowLocal();
  }

  /// Called from `didChangeAppLifecycleState` when the app returns to
  /// `resumed`. If more than [kAppLockRelockThreshold] has passed since it
  /// was paused, it locks again.
  void onAppResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;

    if (!_lockPreferenceActive || pausedAt == null) return;

    final elapsed = nowLocal().difference(pausedAt);
    if (elapsed >= kAppLockRelockThreshold) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Triggers the biometric prompt. Before requesting it, re-checks that the
  /// device still has some method configured (PIN/pattern/password or
  /// biometrics): if the user removed it after enabling the lock, there is
  /// no point spending an attempt — we simply notify and disable the
  /// preference so the app doesn't get stuck again next time (see
  /// [deviceLostSupport] and PreferencesScreen).
  ///
  /// If the device is still supported but the fingerprint/face doesn't match
  /// or the user cancels, it counts as a failed attempt. Once
  /// [kAppLockMaxFailedAttempts] is exhausted, it signs out — retrying
  /// without limit on the lock screen is not a reasonable option.
  Future<void> authenticate() async {
    if (_isAuthenticating) return;

    _isAuthenticating = true;
    notifyListeners();

    final stillSupported = await _biometricService.isSupported();
    if (!stillSupported) {
      _deviceLostSupport = true;
      _isAuthenticating = false;
      await _preferencesViewModel.setBiometricLockEnabled(false);
      notifyListeners();
      return;
    }

    final success = await _biometricService.authenticate();

    if (success) {
      _isLocked = false;
      _failedAttempts = 0;
      _isAuthenticating = false;
      notifyListeners();
      return;
    }

    _failedAttempts++;
    _isAuthenticating = false;

    if (_failedAttempts >= kAppLockMaxFailedAttempts) {
      _failedAttempts = 0;
      _isLocked = false;
      notifyListeners();
      await _authViewModel.signOut();
      return;
    }

    notifyListeners();
  }
}
