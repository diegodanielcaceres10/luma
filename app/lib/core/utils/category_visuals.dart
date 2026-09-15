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

/// Catálogo fijo de íconos disponibles para categorías. Es la fuente única
/// de verdad tanto para el picker del formulario como para el mapeo de
/// `categories.icon` -> IconData. Si agregas una entrada acá, aparece
/// automáticamente en el selector.
const Map<String, IconData> kCategoryIcons = {
  'home': Icons.home_rounded,
  'food': Icons.restaurant_rounded,
  'car': Icons.directions_car_rounded,
  'entertainment': Icons.sports_esports_rounded,
  'salary': Icons.arrow_downward_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'health': Icons.local_hospital_rounded,
  'education': Icons.school_rounded,
  'travel': Icons.flight_rounded,
  'gift': Icons.card_giftcard_rounded,
  'phone': Icons.phone_iphone_rounded,
  'other': Icons.more_horiz_rounded,
};

/// Alias antiguos que pueden existir ya guardados en la DB, mapeados a una
/// entrada de [kCategoryIcons].
const Map<String, String> _iconAliases = {
  'housing': 'home',
  'restaurant': 'food',
  'transport': 'car',
  'games': 'entertainment',
  'income': 'salary',
};

/// Mapea el nombre de icono guardado en `categories.icon` a un IconData.
IconData iconFromName(String? name) {
  if (name == null) return kCategoryIcons['other']!;
  final resolved = _iconAliases[name] ?? name;
  return kCategoryIcons[resolved] ?? kCategoryIcons['other']!;
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
