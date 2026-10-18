import '../../domain/notification_log_entry.dart';

/// A problem that keeps notifications from arriving, shaped for an error
/// report. It carries no data of the user: only the kind of problem and the
/// technical detail already shown in the notification log.
class NotificationHealthIssue implements Exception {
  final NotificationLogKind kind;
  final String? detail;

  const NotificationHealthIssue({required this.kind, this.detail});

  @override
  String toString() => detail == null
      ? 'NotificationHealthIssue(${kind.name})'
      : 'NotificationHealthIssue(${kind.name}): $detail';
}
