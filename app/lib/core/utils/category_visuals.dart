import 'package:flutter/material.dart';

/// Convierte un color hex ('#4F46E5' o '4F46E5') a Color.
/// Si viene nulo o inválido, devuelve [fallback].
Color colorFromHex(String? hex, {Color fallback = Colors.grey}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse('ff$cleaned', radix: 16);
  return value != null ? Color(value) : fallback;
}

/// Mapea el nombre de icono guardado en `categories.icon` a un IconData.
/// AJUSTAR según la convención que uses al sembrar categorías
/// (por ahora asume nombres simples en inglés: 'home', 'food', etc.).
IconData iconFromName(String? name) {
  switch (name) {
    case 'home':
    case 'housing':
      return Icons.home_rounded;
    case 'food':
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'car':
    case 'transport':
      return Icons.directions_car_rounded;
    case 'entertainment':
    case 'games':
      return Icons.sports_esports_rounded;
    case 'salary':
    case 'income':
      return Icons.arrow_downward_rounded;
    default:
      return Icons.more_horiz_rounded;
  }
}
