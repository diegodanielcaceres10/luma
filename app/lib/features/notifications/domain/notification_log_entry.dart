/// What a notification log entry reports.
enum NotificationLogKind {
  /// The daily check ran and every check finished.
  runOk,

  /// The daily check ran but at least one check failed.
  runFailed,

  /// The daily check ran with no signed-in session to read data with.
  runSkippedNoSession,

  /// The daily check ran without the build-time configuration.
  runSkippedNoConfig,

  /// The system does not let the app show notifications.
  permissionDenied,

  /// The daily check has not run for longer than expected.
  workerStale;

  /// Whether this reports a problem, as opposed to a healthy run.
  bool get isProblem => this != runOk;
}

/// One line of the notification log: when it happened, what, and how many
/// notifications that run showed.
class NotificationLogEntry {
  final DateTime at;
  final NotificationLogKind kind;

  /// Notifications shown by the run; 0 for entries that are not a run.
  final int shown;

  /// Technical detail, shown as is in the log (an error message, say).
  final String? detail;

  const NotificationLogEntry({
    required this.at,
    required this.kind,
    this.shown = 0,
    this.detail,
  });

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'kind': kind.name,
        'shown': shown,
        if (detail != null) 'detail': detail,
      };

  /// Reads an entry saved by [toJson]. Returns null for anything malformed,
  /// so one bad item does not hide the rest of the log.
  static NotificationLogEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;

    final at = DateTime.tryParse('${json['at']}');
    if (at == null) return null;

    NotificationLogKind? kind;
    for (final candidate in NotificationLogKind.values) {
      if (candidate.name == json['kind']) kind = candidate;
    }
    if (kind == null) return null;

    final shown = json['shown'];
    final detail = json['detail'];
    return NotificationLogEntry(
      at: at,
      kind: kind,
      shown: shown is int ? shown : 0,
      detail: detail is String ? detail : null,
    );
  }
}
