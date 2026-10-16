import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/notification_log_entry.dart';

/// Where the notification log is kept: a few string values by key.
abstract interface class NotificationLogStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Stores the log with `SharedPreferencesAsync`, which reads straight from
/// the platform. That matters here: the daily task runs in its own isolate,
/// and a cached copy would not see what the other isolate wrote.
///
/// The plugin is created on first use, so building this never fails.
class PreferencesNotificationLogStore implements NotificationLogStore {
  SharedPreferencesAsync? _prefs;

  SharedPreferencesAsync get _instance => _prefs ??= SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _instance.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _instance.setString(key, value);

  @override
  Future<void> delete(String key) => _instance.remove(key);
}

/// Keeps the latest notification events (daily runs and problems found when
/// the app opens) on this device, so a failure that used to disappear can be
/// read later.
///
/// Diagnostics must never break the app or the background task, so every
/// method swallows its errors: reads come back empty and writes are skipped.
class NotificationLogRepository {
  final NotificationLogStore _store;

  NotificationLogRepository({NotificationLogStore? store})
      : _store = store ?? PreferencesNotificationLogStore();

  /// Entries kept; the oldest ones are dropped beyond this.
  static const maxEntries = 20;

  static const _entriesKey = 'notifications.log';
  static const _lastRunKey = 'notifications.last_run_at';
  static const _baselineKey = 'notifications.registered_at';

  /// The saved entries, newest first.
  Future<List<NotificationLogEntry>> entries() async {
    try {
      final raw = await _store.read(_entriesKey);
      if (raw == null) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .map(NotificationLogEntry.tryFromJson)
          .whereType<NotificationLogEntry>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Adds [entry] at the top of the log.
  Future<void> record(NotificationLogEntry entry) async {
    try {
      final updated = [entry, ...await entries()].take(maxEntries).toList();
      await _store.write(
        _entriesKey,
        jsonEncode([for (final item in updated) item.toJson()]),
      );
    } catch (_) {}
  }

  /// Like [record], and also marks that the daily check ran at that moment.
  Future<void> recordRun(NotificationLogEntry entry) async {
    await record(entry);
    await _writeDate(_lastRunKey, entry.at);
  }

  /// When the daily check last ran, or null if it never did.
  Future<DateTime?> lastRunAt() => _readDate(_lastRunKey);

  /// When the task was first seen enabled, or null if it was not.
  Future<DateTime?> baselineAt() => _readDate(_baselineKey);

  /// Remembers [at] as the moment the task was first seen enabled, unless
  /// that is already known.
  Future<void> ensureBaseline(DateTime at) async {
    if (await baselineAt() != null) return;
    await _writeDate(_baselineKey, at);
  }

  /// Forgets when the task was first seen enabled, for when the user turns
  /// notifications off.
  Future<void> clearBaseline() async {
    try {
      await _store.delete(_baselineKey);
    } catch (_) {}
  }

  Future<DateTime?> _readDate(String key) async {
    try {
      final raw = await _store.read(key);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDate(String key, DateTime value) async {
    try {
      await _store.write(key, value.toIso8601String());
    } catch (_) {}
  }
}
