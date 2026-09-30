import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Status bar style for the whole app: every screen has the dark brand
/// gradient behind the status bar, so light icons work everywhere.
///
/// Apply it with a nested `AnnotatedRegion<SystemUiOverlayStyle>`, not
/// `SystemChrome.setSystemUIOverlayStyle`: `MaterialApp` re-applies its own
/// style every frame and overrides earlier values (see
/// https://github.com/flutter/flutter/issues/171344).
const appStatusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light, // Android
  statusBarBrightness: Brightness.dark, // iOS
);
