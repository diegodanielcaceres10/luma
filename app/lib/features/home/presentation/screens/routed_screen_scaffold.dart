import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Scaffold for screens opened as a route of their own (forms, lists,
/// initial balances, etc.): gradient background and the screen's content.
/// It draws no AppBar or "back" button: the header, drawer and bottom nav
/// are provided by AppShellScreen from the outside, and each screen brings
/// its own title and back button (`context.goBack()`, see
/// core/navigation/app_back.dart).
class RoutedScreenScaffold extends StatelessWidget {
  final Widget body;

  const RoutedScreenScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackgroundBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.authBackgroundTop,
              AppColors.authBackgroundBottom,
            ],
          ),
        ),
        child: body,
      ),
    );
  }
}
