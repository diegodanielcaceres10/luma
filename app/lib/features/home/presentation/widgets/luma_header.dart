import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/luma_logo.dart';

/// Header compartido por todas las pantallas del shell (AppShellScreen): menú hamburguesa,
/// marca Luma y una acción opcional a la derecha (campana, ajustes, etc.).
class LumaHeader extends StatelessWidget {
  final Widget? trailing;

  const LumaHeader({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.authTextPrimary,
          ),
          const LumaLogo(size: 28),
          const SizedBox(width: 8),
          const Text(
            'Luma',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.authTextPrimary,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing! else const SizedBox(width: 48),
        ],
      ),
    );
  }
}
