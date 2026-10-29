import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:luma/features/auth/presentation/view_models/preferences_view_model.dart';
import 'package:luma/features/notifications/data/services/foreground_push_presenter.dart';
import 'package:luma/features/notifications/data/services/local_notifications_service.dart';
import 'package:luma/features/notifications/data/services/push_token_registrar.dart';
import 'package:luma/features/notifications/presentation/view_models/notifications_view_model.dart';

import '../../../helpers/fakes.dart';

class FakeAuthViewModel extends ChangeNotifier implements AuthViewModel {
  FakeAuthViewModel({this.isAuthenticated = true});

  @override
  bool isAuthenticated;

  void setAuthenticated(bool value) {
    isAuthenticated = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Avoids the notifications plugin, which needs a platform channel.
class FakeLocalNotificationsService implements LocalNotificationsService {
  /// Pass a shared list to check the order of calls across fakes.
  FakeLocalNotificationsService([this.events]);

  final List<String>? events;
  int permissionRequests = 0;
  Object? permissionError;

  @override
  Future<bool> requestPermission() async {
    events?.add('requestPermission');
    permissionRequests++;
    if (permissionError != null) throw permissionError!;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Records which lifecycle calls the view model makes. [holdStart] keeps
/// `start` pending until it completes.
class FakePushTokenRegistrar implements PushTokenRegistrar {
  /// Pass a shared list to check the order of calls across fakes.
  FakePushTokenRegistrar([List<String>? calls]) : calls = calls ?? [];

  final List<String> calls;
  Completer<void>? holdStart;

  @override
  Future<void> start() async {
    calls.add('start');
    await holdStart?.future;
  }

  @override
  Future<void> stopAndRemove() async => calls.add('stopAndRemove');

  @override
  Future<void> release() async => calls.add('release');

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

/// Records which lifecycle calls the view model makes on the presenter.
class FakeForegroundPushPresenter implements ForegroundPushPresenter {
  FakeForegroundPushPresenter([List<String>? calls]) : calls = calls ?? [];

  final List<String> calls;
  bool disposed = false;

  @override
  Future<void> start() async => calls.add('presenter.start');

  @override
  Future<void> stop() async => calls.add('presenter.stop');

  @override
  void dispose() => disposed = true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}

void main() {
  late PreferencesViewModel preferences;
  late FakeAuthViewModel auth;
  late FakePushTokenRegistrar registrar;
  late FakeForegroundPushPresenter presenter;
  late FakeLocalNotificationsService localNotifications;
  late FakeErrorReporter reporter;
  late NotificationsViewModel viewModel;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    preferences = PreferencesViewModel(FakePreferencesRepository());
    auth = FakeAuthViewModel();
    registrar = FakePushTokenRegistrar();
    presenter = FakeForegroundPushPresenter();
    localNotifications = FakeLocalNotificationsService();
    reporter = FakeErrorReporter();
    viewModel = NotificationsViewModel(
      preferencesViewModel: preferences,
      authViewModel: auth,
      pushTokenRegistrar: registrar,
      foregroundPushPresenter: presenter,
      localNotificationsService: localNotifications,
      reporter: () async => reporter,
    );
    await viewModel.initialize();
  });

  tearDown(() {
    viewModel.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  group('NotificationsViewModel push token', () {
    test('enabled and signed in registers once', () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      expect(registrar.calls, ['start']);
    });

    test('enabled while signed out does nothing, then signing in starts',
        () async {
      auth.setAuthenticated(false);
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();
      expect(registrar.calls, isEmpty);

      auth.setAuthenticated(true);
      await pumpEventQueue();
      expect(registrar.calls, ['start']);
    });

    test('unrelated notifications do not repeat start', () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      await preferences.setCurrencyCode('EUR');
      auth.setAuthenticated(true);
      await pumpEventQueue();

      expect(registrar.calls, ['start']);
    });

    test('turning notifications off removes the token', () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      await preferences.setNotificationsEnabled(false);
      await pumpEventQueue();

      expect(registrar.calls, ['start', 'stopAndRemove']);
    });

    test('signing out with notifications on releases the token', () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      auth.setAuthenticated(false);
      await pumpEventQueue();
      expect(registrar.calls, ['start', 'release']);

      auth.setAuthenticated(true);
      await pumpEventQueue();
      expect(registrar.calls, ['start', 'release', 'start']);
    });

    test('on then off in a row keeps the order', () async {
      registrar.holdStart = Completer<void>();
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      await preferences.setNotificationsEnabled(false);
      await pumpEventQueue();
      // start has not finished, so the removal must still be waiting.
      expect(registrar.calls, ['start']);

      registrar.holdStart!.complete();
      await pumpEventQueue();
      expect(registrar.calls, ['start', 'stopAndRemove']);
    });

    test('the notification permission is still requested once when enabled',
        () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();
      await preferences.setCurrencyCode('EUR');
      await pumpEventQueue();

      expect(localNotifications.permissionRequests, 1);
    });

    test('turning notifications off and on again asks the permission again',
        () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();
      await preferences.setNotificationsEnabled(false);
      await pumpEventQueue();
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      expect(localNotifications.permissionRequests, 2);
    });

    test('the system permission is requested before the token is registered',
        () async {
      final events = <String>[];
      final ordered = NotificationsViewModel(
        preferencesViewModel: preferences,
        authViewModel: FakeAuthViewModel(),
        pushTokenRegistrar: FakePushTokenRegistrar(events),
        foregroundPushPresenter: FakeForegroundPushPresenter(events),
        localNotificationsService: FakeLocalNotificationsService(events),
        reporter: () async => reporter,
      );
      addTearDown(ordered.dispose);

      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      // The view model from setUp also reacts, but writes to its own lists.
      expect(events, ['requestPermission', 'start', 'presenter.start']);
    });

    test('a failing permission request is reported and the token is registered',
        () async {
      localNotifications.permissionError = StateError('boom');
      final errors = <Object>[];

      await runZonedGuarded(() async {
        await preferences.setNotificationsEnabled(true);
        await pumpEventQueue();
      }, (error, _) => errors.add(error));

      expect(registrar.calls, ['start']);
      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.reason, 'Notification permission');
      expect(errors, isEmpty);
    });
  });

  group('NotificationsViewModel on web', () {
    test('registers the token without touching local notifications', () async {
      // Its own preferences and fakes, so the view model from setUp (not web)
      // does not take part.
      final webPreferences = PreferencesViewModel(FakePreferencesRepository());
      // The local plugin does not exist on web; any call would throw.
      final webLocal = FakeLocalNotificationsService()
        ..permissionError = StateError('no plugin');
      final webRegistrar = FakePushTokenRegistrar();
      final webViewModel = NotificationsViewModel(
        preferencesViewModel: webPreferences,
        authViewModel: FakeAuthViewModel(),
        pushTokenRegistrar: webRegistrar,
        foregroundPushPresenter: FakeForegroundPushPresenter(),
        localNotificationsService: webLocal,
        reporter: () async => reporter,
        isWeb: true,
      );
      addTearDown(webViewModel.dispose);
      final errors = <Object>[];

      await runZonedGuarded(() async {
        await webPreferences.setNotificationsEnabled(true);
        await pumpEventQueue();
      }, (error, _) => errors.add(error));

      expect(webRegistrar.calls, ['start']);
      expect(webLocal.permissionRequests, 0);
      expect(errors, isEmpty);
    });
  });

  group('NotificationsViewModel foreground push', () {
    test('starts after the token is registered', () async {
      registrar.holdStart = Completer<void>();
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();
      expect(presenter.calls, isEmpty);

      registrar.holdStart!.complete();
      await pumpEventQueue();
      expect(presenter.calls, ['presenter.start']);
    });

    test('stops before the token is removed when notifications go off',
        () async {
      final events = <String>[];
      final ordered = NotificationsViewModel(
        preferencesViewModel: preferences,
        authViewModel: FakeAuthViewModel(),
        pushTokenRegistrar: FakePushTokenRegistrar(events),
        foregroundPushPresenter: FakeForegroundPushPresenter(events),
        localNotificationsService: localNotifications,
        reporter: () async => reporter,
      );
      addTearDown(ordered.dispose);

      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();
      await preferences.setNotificationsEnabled(false);
      await pumpEventQueue();

      // The first view model from setUp also runs; look at the ordered one.
      expect(events, [
        'start',
        'presenter.start',
        'presenter.stop',
        'stopAndRemove',
      ]);
    });

    test('signing out stops it and signing in starts it again', () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();

      auth.setAuthenticated(false);
      await pumpEventQueue();
      expect(presenter.calls, ['presenter.start', 'presenter.stop']);

      auth.setAuthenticated(true);
      await pumpEventQueue();
      expect(presenter.calls, [
        'presenter.start',
        'presenter.stop',
        'presenter.start',
      ]);
    });

    test('unrelated changes do not restart it', () async {
      await preferences.setNotificationsEnabled(true);
      await pumpEventQueue();
      await preferences.setCurrencyCode('EUR');
      await pumpEventQueue();

      expect(presenter.calls, ['presenter.start']);
    });

    test('dispose releases the presenter', () async {
      viewModel.dispose();

      expect(presenter.disposed, isTrue);
    });
  });
}
