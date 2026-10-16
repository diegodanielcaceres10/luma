import 'notification_log_entry.dart';

/// How long the daily check may go without running before it is reported.
/// The task is meant to run every 24 hours; the extra margin absorbs the
/// delays Android adds to background work.
const Duration kWorkerStaleAfter = Duration(hours: 36);

/// The problem that would stop notifications from arriving, or null when
/// there is none.
///
/// [lastRunAt] is when the daily check last ran and [baselineAt] when the
/// task was first seen enabled; the later of the two is when the clock starts,
/// so a task that was just enabled is not reported as stale.
NotificationLogKind? notificationHealthIssue({
  required bool allowed,
  required DateTime? lastRunAt,
  required DateTime? baselineAt,
  required DateTime now,
}) {
  if (!allowed) return NotificationLogKind.permissionDenied;

  final DateTime? reference;
  if (lastRunAt == null) {
    reference = baselineAt;
  } else if (baselineAt == null) {
    reference = lastRunAt;
  } else {
    reference = lastRunAt.isAfter(baselineAt) ? lastRunAt : baselineAt;
  }
  if (reference == null) return null;

  return now.difference(reference) > kWorkerStaleAfter
      ? NotificationLogKind.workerStale
      : null;
}
