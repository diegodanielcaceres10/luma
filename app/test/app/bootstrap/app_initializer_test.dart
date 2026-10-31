import 'package:flutter_test/flutter_test.dart';
import 'package:luma/app/bootstrap/app_initializer.dart';
import 'package:luma/features/home/data/models/version_check_result.dart';

void main() {
  VersionCheckResult versionResult(VersionCheckStatus status) {
    return VersionCheckResult(
      status: status,
      message: 'message for $status',
      installedVersion: '3.1.0',
      currentVersion: '3.1.0',
      minVersion: '3.1.0',
    );
  }

  AppInitializer initializer({
    Future<void> Function()? initializeBackend,
    required Future<VersionCheckResult?> Function() checkVersion,
  }) {
    return AppInitializer(
      initializeBackend: initializeBackend ?? () async {},
      checkVersion: checkVersion,
    );
  }

  test('returns BootstrapReady without message when the version is updated',
      () async {
    final result = await initializer(
      checkVersion: () async => versionResult(VersionCheckStatus.updated),
    ).run();

    expect(result, isA<BootstrapReady>());
    expect((result as BootstrapReady).pendingUpdateMessage, isNull);
  });

  test('returns BootstrapReady with the message when outdatedButUsable',
      () async {
    final outdated = versionResult(VersionCheckStatus.outdatedButUsable);

    final result = await initializer(checkVersion: () async => outdated).run();

    expect(result, isA<BootstrapReady>());
    expect((result as BootstrapReady).pendingUpdateMessage, outdated.message);
  });

  test('returns BootstrapBlocked with the message when blocked', () async {
    final blocked = versionResult(VersionCheckStatus.blocked);

    final result = await initializer(checkVersion: () async => blocked).run();

    expect(result, isA<BootstrapBlocked>());
    expect((result as BootstrapBlocked).message, blocked.message);
  });

  test('returns BootstrapReady when the version check returns null', () async {
    final result = await initializer(checkVersion: () async => null).run();

    expect(result, isA<BootstrapReady>());
    expect((result as BootstrapReady).pendingUpdateMessage, isNull);
  });

  test('initializes the backend before checking the version', () async {
    final calls = <String>[];

    await initializer(
      initializeBackend: () async => calls.add('backend'),
      checkVersion: () async {
        calls.add('version');
        return null;
      },
    ).run();

    expect(calls, ['backend', 'version']);
  });

  test(
      'rethrows the backend error and does not check the version when '
      'initializeBackend fails', () async {
    var versionChecks = 0;
    final failing = initializer(
      initializeBackend: () async => throw StateError('backend down'),
      checkVersion: () async {
        versionChecks++;
        return null;
      },
    );

    await expectLater(failing.run(), throwsStateError);
    expect(versionChecks, 0);
  });

  test('rethrows a backend error that is not an Exception', () async {
    final failing = initializer(
      initializeBackend: () async => throw 'plain string error',
      checkVersion: () async => null,
    );

    await expectLater(failing.run(), throwsA('plain string error'));
  });
}
