import 'package:flutter/material.dart';

/// Convierte un color hex ('#4F46E5' o '4F46E5') a Color.
/// Si viene nulo o inválido, devuelve [fallback].
Color colorFromHex(String? hex, {Color fallback = Colors.grey}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse('ff$cleaned', radix: 16);
  return value != null ? Color(value) : fallback;
}

/// Convierte un Color de vuelta a hex ('#4F46E5'), para guardar en la DB.
String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

/// Paleta fija de colores para el picker de categorías. Elegidos para verse
/// bien tanto sobre fondo oscuro (chips propios) como en textos/íconos
/// sobre las cards con fondo authCardFill.
const List<String> kCategoryColors = [
  '#4CBB7A', // authAccent (verde marca)
  '#4F46E5', // indigo
  '#0EA5E9', // sky
  '#8B5CF6', // violeta
  '#EC4899', // rosa
  '#F59E0B', // ámbar
  '#EF6F5B', // authExpense (coral)
  '#94A3B8', // gris neutro
];
