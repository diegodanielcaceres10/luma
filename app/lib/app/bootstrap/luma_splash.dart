import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/widgets/layout/luma_logo.dart';
import '../theme/app_colors.dart';

/// Splash with the animated leaf. It loops while [ready] is false and, once
/// it turns true, finishes the loop in progress, plays the outro and calls
/// [onFinished] exactly once.
///
/// If the animation cannot load, or the system asks to reduce motion, the
/// static logo is shown instead and [onFinished] is called as soon as [ready]
/// is true: a decoration must never hold up the app.
class LumaSplash extends StatefulWidget {
  /// The leaf stays still this long before it starts moving, so it gets seen
  /// even when the app is ready almost immediately.
  static const startDelay = Duration(seconds: 1);

  /// One pass of the looping part of the animation (frames 0-60 of the asset).
  static const loopDuration = Duration(seconds: 3);

  /// The closing part of the animation (frames 60-90 of the asset).
  static const outroDuration = Duration(seconds: 1);

  final bool ready;
  final VoidCallback onFinished;

  const LumaSplash({super.key, required this.ready, required this.onFinished});

  @override
  State<LumaSplash> createState() => _LumaSplashState();
}

class _LumaSplashState extends State<LumaSplash>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/animations/luma_splash.json';

  // Mirrors assets/animations/luma_splash.json: 90 frames, the loop covers
  // frames 0-60 and the outro frames 60-90. Frame 60 looks like frame 0, so
  // restarting the loop has no visible jump. The durations of the public
  // constants stretch or squeeze those frames; they do not change the asset.
  static const _loopEnd = 60 / 90;

  // The canvas keeps a 32 px margin on each side of 512, so the leaf is 87.5%
  // of it. Sized this way the leaf is 96 px high, like the web splash.
  static const _leafHeight = 96.0;
  static const _leafToCanvasRatio = 0.875;
  static const _canvasSize = _leafHeight / _leafToCanvasRatio;

  late final AnimationController _controller;
  Timer? _startTimer;
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
        // Frame 0 is shown still until the delay is over.
        _startTimer = Timer(LumaSplash.startDelay, _playLoop);
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
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _playLoop() {
    _controller.value = 0;
    _controller
        .animateTo(_loopEnd, duration: LumaSplash.loopDuration)
        .then((_) {
      if (!mounted) return;
      if (widget.ready) {
        _playOutro();
      } else {
        _playLoop();
      }
    });
  }

  void _playOutro() {
    _controller
        .animateTo(1, duration: LumaSplash.outroDuration)
        .then((_) => _finish());
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
