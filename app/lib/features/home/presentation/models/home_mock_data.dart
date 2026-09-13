import 'package:flutter/material.dart';

class CategorySpend {
  final String label;
  final String amount;
  final String percent;
  final Color dotColor;
  final IconData icon;

  const CategorySpend({
    required this.label,
    required this.amount,
    required this.percent,
    required this.dotColor,
    required this.icon,
  });
}

class MovementItem {
  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
  final IconData icon;
  final Color iconColor;

  const MovementItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.icon,
    required this.iconColor,
  });
}
