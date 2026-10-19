import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import 'pending_movement.dart';
import 'pending_movement_tile.dart';

/// Read-only recap of already-queued movements, without the delete button
/// [MovementsList] has — used in a review/confirmation step, after the
/// user is done adding them via [PendingMovementsSection].
class PendingMovementsReadOnlyList extends StatelessWidget {
  final List<PendingMovement> movements;
  final String currency;

  const PendingMovementsReadOnlyList({
    super.key,
    required this.movements,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < movements.length; i++) ...[
            PendingMovementTile(movement: movements[i], currency: currency),
            if (i < movements.length - 1)
              const Divider(color: AppColors.authCardBorder, height: 1),
          ],
        ],
      ),
    );
  }
}
