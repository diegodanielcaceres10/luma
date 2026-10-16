import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/notification_health_rule.dart';
import '../../domain/notification_log_entry.dart';
import '../repositories/notification_log_repository.dart';

/// Looks, from the app itself, for the problems the daily background task
/// cannot report because it is the one that is not running: notifications
/// blocked by the system, or no run for too long. What it finds goes to the
/// notification log.
class NotificationHealthMonitor {
  final NotificationLogRepository _log;
  final Future<bool> Function() _notificationsAllowed;
  final DateTime Function() _now;

  NotificationHealthMonitor({
    required NotificationLogRepository log,
    required Future<bool> Function() notificationsAllowed,
    DateTime Function()? now,
  })  : _log = log,
        _notificationsAllowed = notificationsAllowed,
        _now = now ?? nowLocal;

  /// The same problem is not logged again before this much time passes, so
  /// opening the app several times a day does not fill the log.
  static const repeatAfter = Duration(hours: 12);

  /// To run when the app starts with notifications enabled. Logs a problem
  /// if there is one; never throws.
  Future<void> check() async {
    try {
      final now = _now();
      await _log.ensureBaseline(now);

      final lastRunAt = await _log.lastRunAt();
      final issue = notificationHealthIssue(
        allowed: await _notificationsAllowed(),
        lastRunAt: lastRunAt,
        baselineAt: await _log.baselineAt(),
        now: now,
      );
      if (issue == null) return;

      final alreadyLogged = (await _log.entries()).any(
        (entry) =>
            entry.kind == issue && now.difference(entry.at) < repeatAfter,
      );
      if (alreadyLogged) return;

      await _log.record(
        NotificationLogEntry(
          at: now,
          kind: issue,
          detail: issue == NotificationLogKind.workerStale
              ? _staleDetail(lastRunAt)
              : null,
        ),
      );
    } catch (_) {}
  }

  /// To run when the user turns notifications off, so turning them on again
  /// starts counting from scratch.
  Future<void> reset() => _log.clearBaseline();

  String _staleDetail(DateTime? lastRunAt) => lastRunAt == null
      ? 'No hubo ninguna revisión desde que se activaron las notificaciones.'
      : 'Última revisión: ${formatDateTime(lastRunAt)}.';
}
