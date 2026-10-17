import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../app/theme/app_colors.dart';
import 'max_width_frame.dart';
import 'primary_button.dart';
import 'text_action_button.dart';

/// Full-screen crop page for web, styled like the rest of the app. Plugged into
/// `WebUiSettings.customRouteBuilder`, which hands over the cropper and the
/// callbacks to drive it.
///
/// The cropper fills whatever space is left, so on a phone it is as large as
/// the screen allows (the old dialog capped it at a small square). The plugin
/// sizes its view to 100% of its parent, so no fixed size is needed.
class ThemedCropperPage extends StatefulWidget {
  final Widget cropper;
  final VoidCallback initCropper;
  final Future<String?> Function() crop;
  final void Function(RotationAngle) rotate;
  final void Function(num) scale;

  const ThemedCropperPage({
    super.key,
    required this.cropper,
    required this.initCropper,
    required this.crop,
    required this.rotate,
    required this.scale,
  });

  /// Route for `WebUiSettings.customRouteBuilder`.
  static PageRoute<String> route(
    Widget cropper,
    VoidCallback initCropper,
    Future<String?> Function() crop,
    void Function(RotationAngle) rotate,
    void Function(num) scale,
  ) {
    return MaterialPageRoute<String>(
      builder: (_) => ThemedCropperPage(
        cropper: cropper,
        initCropper: initCropper,
        crop: crop,
        rotate: rotate,
        scale: scale,
      ),
    );
  }

  @override
  State<ThemedCropperPage> createState() => _ThemedCropperPageState();
}

class _ThemedCropperPageState extends State<ThemedCropperPage> {
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
    return Scaffold(
      backgroundColor: AppColors.authBackgroundTop,
      body: SafeArea(
        child: MaxWidthFrame(
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
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.expand(child: widget.cropper),
                  ),
                ),
                const SizedBox(height: 8),
                _buildZoomBar(context),
                const SizedBox(height: 8),
                _buildActions(),
              ],
            ),
          ),
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
        TextActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
        PrimaryButton(
          label: 'Recortar',
          onPressed: _doCrop,
        ),
      ],
    );
  }
}
