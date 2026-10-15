import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'primary_button.dart';
import 'secondary_button.dart';
import 'text_action_button.dart';

/// What the user decided after seeing the cropped image.
enum CropPreviewAction { send, recrop, cancel }

/// Outcome of the review dialog. [value] is what the send action returned and
/// is only set when [action] is [CropPreviewAction.send].
typedef CropReview<T> = ({CropPreviewAction action, T? value});

/// Message shown inside the dialog when the send action fails.
const cropSendErrorMessage =
    'Servicio no disponible. Intente más tarde o consulte a su administrador.';

/// Shows [bytes], exactly what is about to be sent, and asks whether to send
/// it, crop it again or give up.
///
/// "Enviar" runs [onSend] without closing the dialog: it shows progress, and
/// closes with the result once [onSend] succeeds. If [onSend] throws, the
/// dialog stays open with an error and "Reintentar", so the same image can be
/// sent again, cropped again or dropped.
///
/// The user must choose: tapping outside the dialog does nothing, and going
/// back counts as cancel, except while sending.
Future<CropReview<T>> showCropPreviewDialog<T>(
  BuildContext context,
  Uint8List bytes, {
  required Future<T> Function() onSend,
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
  final Future<T> Function() onSend;

  const _CropPreviewDialog({required this.bytes, required this.onSend});

  @override
  State<_CropPreviewDialog<T>> createState() => _CropPreviewDialogState<T>();
}

class _CropPreviewDialogState<T> extends State<_CropPreviewDialog<T>> {
  bool _isSending = false;
  bool _hasFailed = false;

  Future<void> _send() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _hasFailed = false;
    });

    final T value;
    try {
      value = await widget.onSend();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _hasFailed = true;
      });
      return;
    }

    if (!mounted) return;
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
        insetPadding: const EdgeInsets.all(24),
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
                    onPressed: _isSending
                        ? null
                        : () => _finish(CropPreviewAction.cancel),
                  ),
                  SecondaryButton(
                    label: 'Recortar de nuevo',
                    onPressed: _isSending
                        ? null
                        : () => _finish(CropPreviewAction.recrop),
                  ),
                  PrimaryButton(
                    label: _hasFailed ? 'Reintentar' : 'Enviar',
                    isLoading: _isSending,
                    disabledAlpha: 0.6,
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

  /// Progress while sending, or the error of the last attempt. Nothing
  /// otherwise.
  Widget _buildStatus() {
    if (_isSending) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.authAccent,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Enviando la imagen…',
                style: TextStyle(
                  color: AppColors.authTextSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Semantics(
          liveRegion: true,
          child: const Text(
            cropSendErrorMessage,
            style: TextStyle(
              color: AppColors.authExpense,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
