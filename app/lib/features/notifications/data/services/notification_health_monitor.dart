import '../../../../core/diagnostics/error_reporter.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/notification_health_rule.dart';
import '../../domain/notification_log_entry.dart';
import '../repositories/notification_log_repository.dart';
import 'notification_health_issue.dart';

/// Looks, from the app itself, for the problems the daily background task
/// cannot report because it is the one that is not running: notifications
/// blocked by the system, or no run for too long. What it finds goes to the
/// notification log and to the error reporter.
class NotificationHealthMonitor {
  final NotificationLogRepository _log;
  final Future<bool> Function() _notificationsAllowed;
  final Future<ErrorReporter> Function() _reporter;
  final DateTime Function() _now;

  /// [reporter] is resolved only when there is a problem to report, so a
  /// healthy check never starts it. It defaults to a reporter that discards
  /// everything.
  NotificationHealthMonitor({
    required NotificationLogRepository log,
    required Future<bool> Function() notificationsAllowed,
    Future<ErrorReporter> Function()? reporter,
    DateTime Function()? now,
  })  : _log = log,
        _notificationsAllowed = notificationsAllowed,
        _reporter = reporter ?? _noReporter,
        _now = now ?? nowLocal;

  static Future<ErrorReporter> _noReporter() async =>
      const NoopErrorReporter();

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

      final detail = issue == NotificationLogKind.workerStale
          ? _staleDetail(lastRunAt)
          : null;
      await _log.record(
        NotificationLogEntry(at: now, kind: issue, detail: detail),
      );
      await _report(issue, detail);
    } catch (_) {}
  }

  /// Sends the problem to the error reporter. It runs after the log write
  /// and only for a problem that was not already logged, so it is subject to
  /// the same [repeatAfter] spacing.
  Future<void> _report(NotificationLogKind issue, String? detail) async {
    try {
      final reporter = await _reporter();
      await reporter.recordError(
        NotificationHealthIssue(kind: issue, detail: detail),
        StackTrace.current,
        reason: 'Notification health check',
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
