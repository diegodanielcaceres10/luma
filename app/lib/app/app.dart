import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Placeholder(),
    );
  }
}
