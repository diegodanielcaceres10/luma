import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Contenido temporal para pestañas del bottom nav que todavía no tienen
/// pantalla propia (Movimientos, Estadísticas).
class PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const PlaceholderTab({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              '$label — próximamente',
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
