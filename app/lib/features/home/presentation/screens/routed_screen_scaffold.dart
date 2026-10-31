import 'package:flutter/material.dart';

/// Pass-through wrapper for screens opened as a route of their own (forms,
/// lists, initial balances, etc.).
///
/// The outer shell ([AppShellScreen]) already provides the Scaffold and the
/// unified dark green gradient background for the entire app. This widget
/// renders the [body] directly so the background is seamless, transparent,
/// and consistent across all screens without duplicating gradients.
class RoutedScreenScaffold extends StatelessWidget {
  final Widget body;

  const RoutedScreenScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return body;
  }
}
