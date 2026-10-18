import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../utils/image_cropping.dart';
import 'primary_button.dart';
import 'text_action_button.dart';

/// Opens the crop screen for [bytes] and returns the cropped image as a JPEG,
/// or null when the user cancels.
Future<Uint8List?> showImageCropScreen(
  BuildContext context, {
  required Uint8List bytes,
  int quality = 85,
  int? maxWidth,
}) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      builder: (_) => ImageCropScreen(
        bytes: bytes,
        quality: quality,
        maxWidth: maxWidth,
      ),
    ),
  );
}

/// Full-screen free-form crop editor for Android and iOS.
///
/// Unlike the native croppers it can be resized by dragging any of the four
/// corners or any of the four sides, each with a generous touch area. The
/// image can be zoomed and moved under the crop frame, and rotated in quarter
/// turns.
class ImageCropScreen extends StatefulWidget {
  final Uint8List bytes;
  final int quality;
  final int? maxWidth;

  const ImageCropScreen({
    super.key,
    required this.bytes,
    this.quality = 85,
    this.maxWidth,
  });

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  // Touch area around each corner and side, on both sides of the frame.
  static const double _hitTestSize = 28;

  final ImageEditorController _controller = ImageEditorController();
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _crop() async {
    if (_processing) return;

    final action = _controller.editActionDetails;
    final rect = _controller.getCropRect();
    // The editor is still loading the image.
    if (action == null || rect == null) return;

    setState(() => _processing = true);
    try {
      final result = await cropImageBytes(CropJob(
        bytes: widget.bytes,
        // Without changes to the frame the whole image is kept.
        cropLeft: action.needCrop ? rect.left.round() : null,
        cropTop: action.needCrop ? rect.top.round() : null,
        cropWidth: action.needCrop ? rect.width.round() : null,
        cropHeight: action.needCrop ? rect.height.round() : null,
        rotationDegrees: action.rotateDegrees,
        flipHorizontal: action.flipY,
        quality: widget.quality,
        maxWidth: widget.maxWidth,
      ));
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo recortar la imagen. Intenta de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackgroundTop,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recortar',
                style: TextStyle(
                  color: AppColors.authTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Arrastra las esquinas o los bordes para ajustar el recorte.',
                style: TextStyle(
                  color: AppColors.authTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: IgnorePointer(
                  ignoring: _processing,
                  child: _buildEditor(),
                ),
              ),
              const SizedBox(height: 8),
              _buildTools(),
              const SizedBox(height: 8),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return ExtendedImage.memory(
      widget.bytes,
      fit: BoxFit.contain,
      mode: ExtendedImageMode.editor,
      enableLoadState: true,
      initEditorConfigHandler: (state) => EditorConfig(
        maxScale: 8,
        // Room around the frame so its sides can be grabbed from outside.
        cropRectPadding: const EdgeInsets.all(_hitTestSize),
        hitTestSize: _hitTestSize,
        cornerSize: const Size(26, 4),
        cornerColor: AppColors.authAccent,
        lineColor: AppColors.authTextPrimary.withValues(alpha: 0.35),
        lineHeight: 0.8,
        cropLayerPainter: const _SideHandlesPainter(),
        initCropRectType: InitCropRectType.imageRect,
        controller: _controller,
      ),
    );
  }

  Widget _buildTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Girar 90° a la izquierda',
          color: AppColors.authTextPrimary,
          icon: const Icon(Icons.rotate_90_degrees_ccw_rounded),
          onPressed: _processing ? null : () => _controller.rotate(degree: -90),
        ),
        IconButton(
          tooltip: 'Restablecer',
          color: AppColors.authTextPrimary,
          icon: const Icon(Icons.restart_alt_rounded),
          onPressed: _processing ? null : _controller.reset,
        ),
        IconButton(
          tooltip: 'Girar 90° a la derecha',
          color: AppColors.authTextPrimary,
          icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
          onPressed: _processing ? null : () => _controller.rotate(degree: 90),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextActionButton(
          label: 'Cancelar',
          onPressed: _processing ? null : () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          label: 'Recortar',
          isLoading: _processing,
          onPressed: _processing ? null : _crop,
        ),
      ],
    );
  }
}

/// Paints the default corner marks plus a bar in the middle of each side, so
/// it is clear that the sides can be dragged too.
class _SideHandlesPainter extends EditorCropLayerPainter {
  const _SideHandlesPainter();

  // A side only gets its bar when it is long enough not to crowd the corners.
  static const double _minSideForHandle = 120;
  static const double _length = 28;
  static const double _thickness = 4;

  @override
  void paintCorners(
    Canvas canvas,
    Size size,
    ExtendedImageCropLayerPainter painter,
  ) {
    super.paintCorners(canvas, size, painter);

    final rect = painter.cropRect;
    final paint = Paint()..color = painter.cornerColor;

    void bar(Offset center, {required bool horizontal}) {
      final handle = Rect.fromCenter(
        center: center,
        width: horizontal ? _length : _thickness,
        height: horizontal ? _thickness : _length,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(handle, const Radius.circular(_thickness / 2)),
        paint,
      );
    }

    if (rect.width >= _minSideForHandle) {
      bar(rect.topCenter, horizontal: true);
      bar(rect.bottomCenter, horizontal: true);
    }
    if (rect.height >= _minSideForHandle) {
      bar(rect.centerLeft, horizontal: false);
      bar(rect.centerRight, horizontal: false);
    }
  }
}
