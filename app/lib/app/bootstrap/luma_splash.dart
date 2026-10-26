import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/widgets/luma_logo.dart';
import '../theme/app_colors.dart';

/// Splash with the animated leaf. It loops while [ready] is false and, once
/// it turns true, finishes the loop in progress, plays the outro and calls
/// [onFinished] exactly once.
///
/// If the animation cannot load, or the system asks to reduce motion, the
/// static logo is shown instead and [onFinished] is called as soon as [ready]
/// is true: a decoration must never hold up the app.
class LumaSplash extends StatefulWidget {
  final bool ready;
  final VoidCallback onFinished;

  const LumaSplash({super.key, required this.ready, required this.onFinished});

  @override
  State<LumaSplash> createState() => _LumaSplashState();
}

class _LumaSplashState extends State<LumaSplash>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/animations/luma_splash.json';

  // These values mirror assets/animations/luma_splash.json: 90 frames at
  // 30 fps, the loop covers frames 0-60 and the outro frames 60-90. Frame 60
  // looks like frame 0, so restarting the loop has no visible jump.
  static const _loopDuration = Duration(seconds: 2);
  static const _outroDuration = Duration(seconds: 1);
  static const _loopEnd = 60 / 90;

  // The canvas keeps a 32 px margin on each side of 512, so the leaf is 87.5%
  // of it. Sized this way the leaf is 96 px high, like the web splash.
  static const _leafHeight = 96.0;
  static const _leafToCanvasRatio = 0.875;
  static const _canvasSize = _leafHeight / _leafToCanvasRatio;

  late final AnimationController _controller;
  bool _started = false;
  bool _reduceMotion = false;
  bool _assetFailed = false;
  bool _finished = false;

  bool get _isStatic => _reduceMotion || _assetFailed;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      if (_reduceMotion) {
        _scheduleFinishIfReady();
      } else {
        _playLoop();
      }
    }
  }

  @override
  void didUpdateWidget(LumaSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.ready && widget.ready && _isStatic) {
      _scheduleFinishIfReady();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playLoop() {
    _controller.value = 0;
    _controller.animateTo(_loopEnd, duration: _loopDuration).then((_) {
      if (!mounted) return;
      if (widget.ready) {
        _playOutro();
      } else {
        _playLoop();
      }
    });
  }

  void _playOutro() {
    _controller.animateTo(1, duration: _outroDuration).then((_) => _finish());
  }

  void _scheduleFinishIfReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.ready) _finish();
    });
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.authBackgroundTop,
      child: Center(
        child: SizedBox(
          key: const ValueKey('luma-splash-canvas'),
          width: _canvasSize,
          height: _canvasSize,
          child: _reduceMotion
              ? const LumaLogo(size: _canvasSize)
              : Lottie.asset(
                  _asset,
                  bundle: DefaultAssetBundle.of(context),
                  controller: _controller,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Called while building: no setState, the fallback is
                    // already what this builder returns.
                    _assetFailed = true;
                    _scheduleFinishIfReady();
                    return const LumaLogo(size: _canvasSize);
                  },
                ),
        ),
      ),
    );
  }
}
