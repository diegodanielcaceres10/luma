import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../ai/scan_stage.dart';
import '../widgets/crop_preview_dialog.dart';
import '../widgets/image_crop_screen.dart';
import '../widgets/themed_cropper_page.dart';

/// An image already cropped by the user, ready to be sent for scanning.
typedef PickedImage = ({Uint8List bytes, String mimeType});

/// Lets the user choose a photo from [source].
typedef ImagePickFn = Future<XFile?> Function(ImageSource source);

/// Shows the cropper for the image at [sourcePath]. Returns the cropped bytes
/// or null when the user cancels.
typedef ImageCropFn = Future<Uint8List?> Function(String sourcePath);

/// Sends [image] to be read. [report] says which stage the request is in; it
/// is only listened to when a preview is shown.
typedef ImageProcessFn<T> = Future<T> Function(
  PickedImage image,
  ScanProgress report,
);

/// Shows the cropped [bytes] and returns what the user decided to do with
/// them. [send] runs the request for the image being shown, passing it the
/// callback that receives its stages; the preview keeps itself open until it
/// succeeds, so the user can retry if it fails.
typedef ImagePreviewFn<T> = Future<CropReview<T>> Function(
  Uint8List bytes,
  Future<T> Function(ScanProgress report) send,
);

/// Picks an image, lets the user crop it and sends it with [process]. Returns
/// what [process] returned, or null if the user cancels any step.
///
/// When [preview] is given, the cropped image is shown before it is sent. The
/// user can send it, crop the original photo again (without picking it anew)
/// or cancel, and a [process] failure is handled there, where it can be
/// retried with the same image. Without [preview] the cropped image goes
/// straight to [process], and its errors are thrown to the caller.
///
/// The picker, the cropper and the preview are injected so the flow can be
/// tested without the platform plugins.
Future<T?> pickCroppedImage<T>({
  required ImageSource source,
  required ImagePickFn pick,
  required ImageCropFn crop,
  required ImageProcessFn<T> process,
  ImagePreviewFn<T>? preview,
}) async {
  final picked = await pick(source);
  if (picked == null) return null;

  while (true) {
    // Always crop from the original photo, never from an earlier crop.
    final bytes = await crop(picked.path);
    if (bytes == null) return null;

    final image = (bytes: bytes, mimeType: detectImageMimeType(bytes));
    if (preview == null) return process(image, (_) {});

    final review = await preview(bytes, (report) => process(image, report));
    switch (review.action) {
      case CropPreviewAction.send:
        return review.value;
      case CropPreviewAction.cancel:
        return null;
      case CropPreviewAction.recrop:
        // Crop the same photo again.
        break;
    }
  }
}

/// Mime type of [bytes] from their magic numbers. The cropper re-encodes the
/// image, so the picker's mime type can no longer be trusted. Anything that is
/// not PNG or WEBP is reported as JPEG, the default output of the cropper.
String detectImageMimeType(Uint8List bytes) {
  final isPng = bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
  if (isPng) return 'image/png';

  // RIFF....WEBP
  final isWebp = bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
  if (isWebp) return 'image/webp';

  return 'image/jpeg';
}

/// Picks a photo from the gallery or the camera, opens the crop screen, shows
/// a preview of the result and sends it with [process]. Returns what
/// [process] returned, or null if the user cancels.
///
/// The preview stays open while [process] runs, and if it throws it offers to
/// retry with the same image (or crop again, or cancel), so a failed request
/// doesn't cost the user the picked photo.
///
/// The photo is picked untouched and compressed once, when it is cropped, so
/// it is not re-encoded twice. The preview shows those same bytes: exactly
/// what will be sent.
Future<T?> pickAndCropImage<T>(
  BuildContext context,
  ImageSource source, {
  required ImageProcessFn<T> process,
  int imageQuality = 85,
  int? maxWidth,
}) {
  return pickCroppedImage<T>(
    source: source,
    pick: (source) => ImagePicker().pickImage(source: source),
    process: process,
    preview: (bytes, send) async {
      // The cropper is async; the screen may be gone by now.
      if (!context.mounted) {
        return (action: CropPreviewAction.cancel, value: null);
      }
      return showCropPreviewDialog<T>(context, bytes, onSend: send);
    },
    crop: (sourcePath) async {
      // The picker is async; the screen may be gone by now.
      if (!context.mounted) return null;

      // Web keeps cropper.js. Android and iOS use our own editor, because the
      // native croppers only let the user drag from the corners.
      if (kIsWeb) {
        return _cropOnWeb(
          context,
          sourcePath,
          quality: imageQuality,
          maxWidth: maxWidth,
        );
      }

      final bytes = await XFile(sourcePath).readAsBytes();
      if (!context.mounted) return null;
      return showImageCropScreen(
        context,
        bytes: bytes,
        quality: imageQuality,
        maxWidth: maxWidth,
      );
    },
  );
}

Future<Uint8List?> _cropOnWeb(
  BuildContext context,
  String sourcePath, {
  required int quality,
  int? maxWidth,
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: quality,
    maxWidth: maxWidth,
    uiSettings: [
      WebUiSettings(
        context: context,
        // Full-screen page instead of a small dialog: the cropper uses all the
        // space available, which matters on a phone browser.
        presentStyle: WebPresentStyle.page,
        customRouteBuilder: ThemedCropperPage.route,
        // Dragging the image moves it; the crop box is resized from its
        // handles. With the default mode a touch outside the box starts a new
        // box, which is easy to trigger by accident on a phone.
        dragMode: WebDragMode.move,
      ),
    ],
  );
  return cropped?.readAsBytes();
}
