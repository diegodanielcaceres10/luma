import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../ai/scan_progress_timeline.dart';
import '../../ai/scan_stage.dart';
import '../buttons/secondary_button.dart';

/// Shows [ScanProgressDialog] for [timeline]. The returned future completes
/// when the popup is closed: by the caller once the scan succeeds, or by the
/// user with "Cerrar" after a failure.
Future<void> showScanProgressDialog(
  BuildContext context,
  ScanProgressTimeline timeline,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ScanProgressDialog(timeline: timeline),
  );
}

/// Popup that follows a scan: a spinner around the icon of the current stage,
/// with its description below. On success it shows a check; on failure it says
/// what went wrong and offers to close it.
///
/// There is no way out while the scan runs: going back is ignored.
class ScanProgressDialog extends StatelessWidget {
  final ScanProgressTimeline timeline;

  const ScanProgressDialog({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        insetPadding: Theme.of(context).dialogTheme.insetPadding ??
            const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: ListenableBuilder(
            listenable: timeline,
            builder: (context, _) {
              final state = timeline.state;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _ProgressContent(
                  // A new key per state makes the switcher fade between them.
                  key: ValueKey((state.stage, state.phase)),
                  state: state,
                  onClose: () => Navigator.of(context).pop(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  static const double _indicatorSize = 72;

  final ScanProgressState state;
  final VoidCallback onClose;

  const _ProgressContent({
    super.key,
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final failed = state.phase == ScanProgressPhase.failed;
    final done = state.phase == ScanProgressPhase.done;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _indicatorSize,
          height: _indicatorSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!failed)
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    // A full ring once everything is done.
                    value: done ? 1 : null,
                    strokeWidth: 3,
                    color: AppColors.authAccent,
                    backgroundColor:
                        AppColors.authAccent.withValues(alpha: 0.15),
                  ),
                ),
              Icon(
                _iconFor(state),
                size: 30,
                color: failed ? AppColors.authExpense : AppColors.authAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text(
            _titleFor(state),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: failed ? AppColors.authExpense : AppColors.authTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (failed) ...[
          const SizedBox(height: 8),
          Text(
            state.message ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.authTextSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          SecondaryButton(label: 'Cerrar', onPressed: onClose),
        ],
      ],
    );
  }

  static IconData _iconFor(ScanProgressState state) {
    return switch (state.phase) {
      ScanProgressPhase.done => Icons.check_rounded,
      ScanProgressPhase.failed => Icons.error_outline_rounded,
      ScanProgressPhase.running => switch (state.stage) {
          ScanStage.preparing => Icons.image_outlined,
          ScanStage.sending => Icons.cloud_upload_outlined,
          ScanStage.processing => Icons.fact_check_outlined,
        },
    };
  }

  static String _titleFor(ScanProgressState state) {
    return switch (state.phase) {
      ScanProgressPhase.done => 'Todo listo',
      ScanProgressPhase.failed => switch (state.stage) {
          ScanStage.preparing => 'No se pudo preparar la imagen',
          ScanStage.sending => 'No se pudo completar el envío',
          ScanStage.processing => 'No se pudo procesar el resultado',
        },
      ScanProgressPhase.running => switch (state.stage) {
          ScanStage.preparing => 'Preparando la imagen',
          ScanStage.sending => 'Enviando y esperando respuesta',
          ScanStage.processing => 'Procesando el resultado',
        },
    };
  }
}
