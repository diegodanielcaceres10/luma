enum VersionCheckStatus { updated, outdatedButUsable, blocked }

class VersionCheckResult {
  final VersionCheckStatus status;
  final String message;
  final String installedVersion;
  final String currentVersion;
  final String minVersion;

  const VersionCheckResult({
    required this.status,
    required this.message,
    required this.installedVersion,
    required this.currentVersion,
    required this.minVersion,
  });

  factory VersionCheckResult.fromMap(Map<String, dynamic> map) {
    return VersionCheckResult(
      status: _statusFromString(map['status'] as String),
      message: map['message'] as String,
      installedVersion: map['installed_version'] as String,
      currentVersion: map['current_version'] as String,
      minVersion: map['min_version'] as String,
    );
  }

  static VersionCheckStatus _statusFromString(String raw) {
    switch (raw) {
      case 'updated':
        return VersionCheckStatus.updated;
      case 'outdated_but_usable':
        return VersionCheckStatus.outdatedButUsable;
      case 'blocked':
        return VersionCheckStatus.blocked;
      default:
        throw ArgumentError('Estado de versión desconocido: $raw');
    }
  }
}
