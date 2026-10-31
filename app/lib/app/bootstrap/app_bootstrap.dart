import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_info.dart';
import '../../core/diagnostics/error_reporter.dart';
import '../theme/app_system_ui.dart';
import '../theme/app_theme.dart';
import 'app_initializer.dart';
import 'bootstrap_error_view.dart';
import 'luma_splash.dart';

/// Runs the startup work behind the animated splash and then shows the app,
/// the update-required screen or, if startup failed, an error with a retry.
class AppBootstrap extends StatefulWidget {
  final AppInitializer initializer;
  final ErrorReporter errorReporter;
  final Widget Function(String? pendingUpdateMessage) appBuilder;
  final Widget Function(String message) blockedBuilder;

  /// Replaces the Lottie splash; tests use it to avoid loading the animation.
  final Widget Function(bool ready, VoidCallback onFinished)? splashBuilder;

  const AppBootstrap({
    super.key,
    required this.initializer,
    required this.errorReporter,
    required this.appBuilder,
    required this.blockedBuilder,
    this.splashBuilder,
  });

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  BootstrapResult? _result;
  bool _failed = false;
  bool _splashFinished = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    // A second tap on "Reintentar" must not start a parallel run.
    if (_running) return;
    _running = true;
    try {
      final result = await widget.initializer.run();
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error, stackTrace) {
      unawaited(widget.errorReporter.recordError(
        error,
        stackTrace,
        reason: 'App initialization failed',
      ));
      if (!mounted) return;
      setState(() => _failed = true);
    } finally {
      _running = false;
    }
  }

  void _retry() {
    if (_running) return;
    setState(() {
      _failed = false;
      _result = null;
      _splashFinished = false;
    });
    unawaited(_run());
  }

  void _onSplashFinished() {
    if (!mounted || _result == null) return;
    setState(() => _splashFinished = true);
  }

  Widget _buildCurrent() {
    if (_failed) {
      return _plainApp(
        const ValueKey('error'),
        BootstrapErrorView(onRetry: _retry),
      );
    }

    final result = _result;
    if (result != null && _splashFinished) {
      return KeyedSubtree(
        key: const ValueKey('app'),
        child: switch (result) {
          BootstrapBlocked(:final message) => widget.blockedBuilder(message),
          BootstrapReady(:final pendingUpdateMessage) =>
            widget.appBuilder(pendingUpdateMessage),
        },
      );
    }

    final splash = widget.splashBuilder?.call(
          result != null,
          _onSplashFinished,
        ) ??
        LumaSplash(ready: result != null, onFinished: _onSplashFinished);
    return _plainApp(const ValueKey('splash'), splash);
  }

  // The splash and the error view live outside LumaApp, so they bring their
  // own minimal MaterialApp.
  Widget _plainApp(Key key, Widget home) {
    return MaterialApp(
      key: key,
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Same style as the main app, so the status bar does not flip from
      // dark to light icons when the splash hands over to the app.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: appStatusBarStyle,
        child: child!,
      ),
      home: home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildCurrent(),
    );
  }
}
