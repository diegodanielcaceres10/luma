import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/repositories/notification_log_repository.dart';
import '../../domain/notification_log_entry.dart';

/// Short name of a log entry kind.
String notificationLogLabel(NotificationLogKind kind) => switch (kind) {
      NotificationLogKind.runOk => 'Revisión correcta',
      NotificationLogKind.runFailed => 'Revisión con errores',
      NotificationLogKind.runSkippedNoSession => 'Sin sesión en segundo plano',
      NotificationLogKind.runSkippedNoConfig => 'Configuración no disponible',
      NotificationLogKind.permissionDenied =>
        'Permiso de notificaciones denegado',
      NotificationLogKind.workerStale => 'La revisión diaria no se ejecuta',
    };

/// What the user can do about a problem entry; null for a healthy run.
String? notificationLogProblemMessage(NotificationLogKind kind) =>
    switch (kind) {
      NotificationLogKind.runOk => null,
      NotificationLogKind.runFailed =>
        'La última revisión terminó con errores. Mirá el detalle en el '
            'registro.',
      NotificationLogKind.runSkippedNoSession =>
        'La última revisión no tenía sesión iniciada. Abrí la app para '
            'renovarla.',
      NotificationLogKind.runSkippedNoConfig =>
        'La última revisión no encontró la configuración de la app.',
      NotificationLogKind.permissionDenied =>
        'Android no deja que Luma muestre notificaciones. Activalas en los '
            'ajustes del sistema.',
      NotificationLogKind.workerStale =>
        'La revisión diaria no se ejecutó en más de un día y medio. Revisá '
            'que Luma no tenga restringida la batería.',
    };

/// Shows when the daily notification check last ran and, on demand, the
/// latest entries of the notification log.
class NotificationLogSection extends StatefulWidget {
  final NotificationLogRepository? repository;

  const NotificationLogSection({super.key, this.repository});

  @override
  State<NotificationLogSection> createState() => _NotificationLogSectionState();
}

class _NotificationLogSectionState extends State<NotificationLogSection> {
  late final NotificationLogRepository _repository =
      widget.repository ?? NotificationLogRepository();

  List<NotificationLogEntry> _entries = const [];
  DateTime? _lastRunAt;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repository.entries();
    final lastRunAt = await _repository.lastRunAt();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _lastRunAt = lastRunAt;
    });
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) _load();
  }

  @override
  Widget build(BuildContext context) {
    final problem = _entries.isNotEmpty && _entries.first.kind.isProblem
        ? notificationLogProblemMessage(_entries.first.kind)
        : null;
    final lastRunAt = _lastRunAt;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        border: Border.all(color: AppColors.authCardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Última revisión automática',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lastRunAt == null
                  ? 'Todavía no se ejecutó'
                  : formatDateTime(lastRunAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.authTextSecondary,
              ),
            ),
            if (problem != null) ...[
              const SizedBox(height: 8),
              Text(
                problem,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.authExpense,
                ),
              ),
            ],
            const SizedBox(height: 8),
            InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _expanded ? 'Ocultar registro' : 'Ver registro',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authAccent,
                  ),
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              if (_entries.isEmpty)
                const Text(
                  'Sin registros todavía.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.authTextFooter,
                  ),
                )
              else
                for (final entry in _entries) _LogEntryRow(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogEntryRow extends StatelessWidget {
  final NotificationLogEntry entry;

  const _LogEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final summary = entry.kind == NotificationLogKind.runOk
        ? '${formatDateTime(entry.at)} · ${notificationLogLabel(entry.kind)}'
            ' · ${entry.shown} avisos'
        : '${formatDateTime(entry.at)} · ${notificationLogLabel(entry.kind)}';
    final detail = entry.detail;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: TextStyle(
              fontSize: 12,
              color: entry.kind.isProblem
                  ? AppColors.authExpense
                  : AppColors.authTextSecondary,
            ),
          ),
          if (detail != null)
            Text(
              detail,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.authTextFooter,
              ),
            ),
        ],
      ),
    );
  }
}
