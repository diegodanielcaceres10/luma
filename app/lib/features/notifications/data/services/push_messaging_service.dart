import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/app_env.dart';

/// A push message received while the app is open, reduced to what the app
/// shows. [tag] identifies the notice (it is also sent as `data.tag`).
class PushMessage {
  const PushMessage({this.title, this.body, this.tag});

  final String? title;
  final String? body;
  final String? tag;
}

/// Thin wrapper over `firebase_messaging`, so the rest of the app does not
/// depend on the plugin directly (same idea as `LocalNotificationsService`).
///
/// Push is set up for Android (like Crashlytics) and for the web build when
/// its Firebase config is present (see [AppEnv.webPushConfigured]). Everywhere
/// else the methods do nothing, so callers do not need their own platform
/// checks.
class PushMessagingService {
  /// [messaging] is for tests; by default the plugin instance is used.
  PushMessagingService({FirebaseMessaging? messaging}) : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  bool get isSupported => kIsWeb
      ? AppEnv.webPushConfigured
      : defaultTargetPlatform == TargetPlatform.android;

  /// Where the app shows messages that arrive while it is open. On web the
  /// local notifications plugin does not exist, so nothing is shown.
  bool get showsForegroundMessages => isSupported && !kIsWeb;

  /// Value stored in `device_tokens.platform`.
  String get platform => kIsWeb ? 'web' : 'android';

  /// Resolved lazily: the plugin instance cannot be read before Firebase
  /// starts. On Android, without options, it reads google-services.json; on
  /// web the options come from the build configuration.
  Future<FirebaseMessaging> _instance() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: kIsWeb
            ? const FirebaseOptions(
                apiKey: AppEnv.firebaseWebApiKey,
                appId: AppEnv.firebaseWebAppId,
                messagingSenderId: AppEnv.firebaseMessagingSenderId,
                projectId: AppEnv.firebaseProjectId,
              )
            : null,
      );
    }
    return _messaging ?? FirebaseMessaging.instance;
  }

  /// Whether the app may show notifications. On web it asks the browser only
  /// while the user has not decided yet. It waits for the user, so callers
  /// must not put a time limit on it. Android asks for its permission
  /// elsewhere (see `LocalNotificationsService.requestPermission`).
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    if (!kIsWeb) return true;

    final messaging = await _instance();
    var settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await messaging.requestPermission();
    }
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<String?> getToken() async {
    if (!isSupported) return null;
    final messaging = await _instance();
    return kIsWeb
        ? messaging.getToken(vapidKey: AppEnv.firebaseVapidKey)
        : messaging.getToken();
  }

  /// Emits whenever FCM rotates the token (reinstall, restored backup...).
  Stream<String> get onTokenRefresh async* {
    if (!isSupported) return;
    yield* (await _instance()).onTokenRefresh;
  }

  /// Invalidates the current token; the next [getToken] returns a new one.
  Future<void> deleteToken() async {
    if (!isSupported) return;
    await (await _instance()).deleteToken();
  }

  /// Messages received while the app is in the foreground. Android does not
  /// show those by itself, so the app has to.
  Stream<PushMessage> get onForegroundMessage async* {
    if (!isSupported) return;
    // The static stream below needs Firebase to be started.
    await _instance();
    yield* FirebaseMessaging.onMessage.map(
      (message) => PushMessage(
        title: message.notification?.title,
        body: message.notification?.body,
        tag: message.data['tag']?.toString(),
      ),
    );
  }
}
