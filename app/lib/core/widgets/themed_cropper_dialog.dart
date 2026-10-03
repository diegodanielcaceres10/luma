import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../app/theme/app_colors.dart';

/// Largest side of the web cropper, in logical pixels.
const double kMaxWebCropperSide = 500;
const double _kMinWebCropperSide = 200;

// Dialog inset plus content padding on both sides.
const double _kHorizontalChrome = 96;
// Title, zoom bar, buttons and paddings stacked around the cropper.
const double _kVerticalChrome = 300;

/// Side of the square web cropper that fits in [screen]. The plugin default is
/// a fixed 500 px, which would overflow on a phone browser.
double webCropperSideFor(Size screen) {
  final side = math.min(
    screen.width - _kHorizontalChrome,
    screen.height - _kVerticalChrome,
  );
  return side.clamp(_kMinWebCropperSide, kMaxWebCropperSide).toDouble();
}

/// Crop dialog for web, styled like the rest of the app. Plugged into
/// `WebUiSettings.customDialogBuilder`, which hands over the cropper and the
/// callbacks to drive it.
class ThemedCropperDialog extends StatefulWidget {
  final Widget cropper;
  final VoidCallback initCropper;
  final Future<String?> Function() crop;
  final void Function(RotationAngle) rotate;
  final void Function(num) scale;

  /// Side of the cropper; must match the size given to `WebUiSettings`.
  final double cropperSide;

  const ThemedCropperDialog({
    super.key,
    required this.cropper,
    required this.initCropper,
    required this.crop,
    required this.rotate,
    required this.scale,
    required this.cropperSide,
  });

  @override
  State<ThemedCropperDialog> createState() => _ThemedCropperDialogState();
}

class _ThemedCropperDialogState extends State<ThemedCropperDialog> {
  static const double _minScale = 1;
  static const double _maxScale = 3;

  bool _processing = false;
  double _scale = _minScale;

  @override
  void initState() {
    super.initState();
    widget.initCropper();
  }

  Future<void> _doCrop() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final result = await widget.crop();
      if (!mounted) return;
      Navigator.of(context).pop(result);
      return;
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
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
              'Recortar',
              style: TextStyle(
                color: AppColors.authTextPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: widget.cropperSide,
                  height: widget.cropperSide,
                  child: widget.cropper,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildZoomBar(context),
            const SizedBox(height: 8),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Girar 90° a la izquierda',
          color: AppColors.authTextPrimary,
          icon: const Icon(Icons.rotate_90_degrees_ccw_rounded),
          onPressed: () => widget.rotate(RotationAngle.counterClockwise90),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.authAccent,
              inactiveTrackColor: AppColors.authCardBorder,
              thumbColor: AppColors.authAccent,
              overlayColor: AppColors.authAccent.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _scale,
              min: _minScale,
              max: _maxScale,
              onChanged: (value) {
                setState(() => _scale = value);
                widget.scale(value);
              },
            ),
          ),
        ),
        IconButton(
          tooltip: 'Girar 90° a la derecha',
          color: AppColors.authTextPrimary,
          icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
          onPressed: () => widget.rotate(RotationAngle.clockwise90),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_processing) {
      return const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.authAccent,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.authTextSecondary),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.authAccent,
            foregroundColor: AppColors.authBackgroundBottom,
          ),
          onPressed: _doCrop,
          child: const Text('Recortar'),
        ),
      ],
    );
  }
}
