import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../ai/scan_failure.dart';
import '../../ai/scan_progress_timeline.dart';
import '../../ai/scan_stage.dart';
import '../buttons/primary_button.dart';
import '../dialogs/scan_progress_dialog.dart';
import '../buttons/secondary_button.dart';
import '../buttons/text_action_button.dart';

/// What the user decided after seeing the cropped image.
enum CropPreviewAction { send, recrop, cancel }

/// Outcome of the review dialog. [value] is what the send action returned and
/// is only set when [action] is [CropPreviewAction.send].
typedef CropReview<T> = ({CropPreviewAction action, T? value});

/// Message shown when the send action fails without saying why. A
/// [ScanFailure] brings its own message.
const cropSendErrorMessage = scanUnavailableMessage;

/// Shows [bytes], exactly what is about to be sent, and asks whether to send
/// it, crop it again or give up.
///
/// "Enviar" runs [onSend] without closing the dialog. A popup follows the
/// stages [onSend] reports (see [ScanProgress]) and, once it succeeds, says
/// "Todo listo" for a moment and closes with the result. If [onSend] throws,
/// the popup shows what failed and the user closes it to come back here, where
/// the error stays with "Reintentar", so the same image can be sent again,
/// cropped again or dropped.
///
/// The user must choose: tapping outside the dialog does nothing, and going
/// back counts as cancel, except while sending.
Future<CropReview<T>> showCropPreviewDialog<T>(
  BuildContext context,
  Uint8List bytes, {
  required Future<T> Function(ScanProgress report) onSend,
}) async {
  final review = await showDialog<CropReview<T>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CropPreviewDialog<T>(bytes: bytes, onSend: onSend),
  );
  return review ?? (action: CropPreviewAction.cancel, value: null);
}

class _CropPreviewDialog<T> extends StatefulWidget {
  final Uint8List bytes;
  final Future<T> Function(ScanProgress report) onSend;

  const _CropPreviewDialog({required this.bytes, required this.onSend});

  @override
  State<_CropPreviewDialog<T>> createState() => _CropPreviewDialogState<T>();
}

class _CropPreviewDialogState<T> extends State<_CropPreviewDialog<T>> {
  /// How faded the buttons look while the image is being sent.
  static const double _disabledAlpha = 0.6;

  bool _isSending = false;

  /// Message of the last failed attempt; null if there was none.
  String? _errorMessage;

  Future<void> _send() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final timeline = ScanProgressTimeline();
    // The popup is closed here once the scan succeeds, or by the user after a
    // failure.
    final popup = showScanProgressDialog(context, timeline);

    final T value;
    try {
      value = await widget.onSend(timeline.report);
    } catch (error) {
      final message =
          error is ScanFailure ? error.userMessage : cropSendErrorMessage;
      timeline.fail(message);
      await popup;
      timeline.dispose();
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = message;
      });
      return;
    }

    await timeline.complete();
    timeline.dispose();
    if (!mounted) return;
    // Closes the popup, which is the topmost route, and then this dialog.
    Navigator.of(context).pop();
    Navigator.of(context).pop<CropReview<T>>(
      (action: CropPreviewAction.send, value: value),
    );
  }

  void _finish(CropPreviewAction action) {
    Navigator.of(context).pop<CropReview<T>>((action: action, value: null));
  }

  @override
  Widget build(BuildContext context) {
    final maxImageHeight = MediaQuery.sizeOf(context).height * 0.5;

    return PopScope(
      // Going back while sending would leave the request without an owner.
      canPop: !_isSending,
      child: Dialog(
        backgroundColor: AppColors.authBackgroundTop,
        surfaceTintColor: Colors.transparent,
        // The theme's insets keep the dialog centered on the content when a
        // sidebar is showing.
        insetPadding: Theme.of(context).dialogTheme.insetPadding ??
            const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.authCardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revisá la imagen',
                style: TextStyle(
                  color: AppColors.authTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esto es lo que se va a enviar. Comprobá que no se vea '
                'ningún dato personal. Podés acercar la imagen con dos dedos.',
                style: TextStyle(
                  color: AppColors.authTextSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxImageHeight),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.memory(
                        widget.bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No se pudo mostrar la imagen.',
                            style:
                                TextStyle(color: AppColors.authTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildStatus(),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextActionButton(
                    label: 'Cancelar',
                    disabledAlpha: _disabledAlpha,
                    onPressed: _isSending
                        ? null
                        : () => _finish(CropPreviewAction.cancel),
                  ),
                  SecondaryButton(
                    label: 'Recortar de nuevo',
                    disabledAlpha: _disabledAlpha,
                    onPressed: _isSending
                        ? null
                        : () => _finish(CropPreviewAction.recrop),
                  ),
                  PrimaryButton(
                    label: _errorMessage != null ? 'Reintentar' : 'Enviar',
                    disabledAlpha: _disabledAlpha,
                    onPressed: _isSending ? null : _send,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The error of the last attempt, if there was one. The progress itself is
  /// shown in the popup.
  Widget _buildStatus() {
    final errorMessage = _errorMessage;
    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        liveRegion: true,
        child: Text(
          errorMessage,
          style: const TextStyle(
            color: AppColors.authExpense,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
