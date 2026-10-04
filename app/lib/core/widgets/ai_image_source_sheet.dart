import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';

/// Asks where an image comes from before it is sent to the AI service, and
/// warns about what that means. Resolves to null when the user dismisses the
/// sheet.
///
/// The warning is the same for every feature that sends images, so it is
/// shown here and not by the callers. Set [allowCamera] to false for flows
/// where only existing files make sense.
Future<ImageSource?> showAiImageSourceSheet(
  BuildContext context, {
  required String title,
  bool allowCamera = true,
}) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.authBackgroundBottom,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.authTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const _PrivacyNotice(),
            const SizedBox(height: 8),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Elegir de la galería',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (allowCamera)
              _SourceTile(
                icon: Icons.photo_camera_rounded,
                label: 'Sacar foto',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.authTextPrimary),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.authTextPrimary),
      ),
      onTap: onTap,
    );
  }
}

/// Warning shown every time before an image is picked. The image is read by a
/// free-tier AI service whose provider may use and review it.
class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.authExpense.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.authExpense.withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.authExpense,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta función es de uso personal y con fines educativos y de '
              'desarrollo. La imagen se envía a un servicio de IA gratuito '
              '(Gemini): Google puede usarla para mejorar sus productos y '
              'personas de su equipo podrían leerla.\n\n'
              'Recortala para que se vea solo lo necesario. No incluyas '
              'datos sensibles (tu nombre, tu dirección, números de cuenta '
              'o de tarjeta, documentos) ni nada que no quieras compartir.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
