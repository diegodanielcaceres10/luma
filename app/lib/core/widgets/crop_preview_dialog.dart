import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// What the user decided after seeing the cropped image.
enum CropPreviewAction { send, recrop, cancel }

/// Shows [bytes], exactly what is about to be sent, and asks whether to send
/// it, crop it again or give up. The user must choose: tapping outside the
/// dialog does nothing, and going back counts as cancel.
Future<CropPreviewAction> showCropPreviewDialog(
  BuildContext context,
  Uint8List bytes,
) async {
  final action = await showDialog<CropPreviewAction>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CropPreviewDialog(bytes: bytes),
  );
  return action ?? CropPreviewAction.cancel;
}

class _CropPreviewDialog extends StatelessWidget {
  final Uint8List bytes;

  const _CropPreviewDialog({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final maxImageHeight = MediaQuery.sizeOf(context).height * 0.5;

    return Dialog(
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
              'Esto es lo que se va a enviar. Comprobá que no se vea ningún '
              'dato personal. Podés acercar la imagen con dos dedos.',
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
                      bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No se pudo mostrar la imagen.',
                          style: TextStyle(color: AppColors.authTextSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(CropPreviewAction.cancel),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.authTextSecondary),
                  ),
                ),
                SecondaryButton(
                  label: 'Recortar de nuevo',
                  onPressed: () =>
                      Navigator.of(context).pop(CropPreviewAction.recrop),
                ),
                PrimaryButton(
                  label: 'Enviar',
                  onPressed: () =>
                      Navigator.of(context).pop(CropPreviewAction.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
