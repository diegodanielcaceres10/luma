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

/// Las claves de ícono Material ('food', 'home'…) son texto ASCII simple; un
/// emoji nunca lo es. Así se distingue qué guarda `categories.icon` sin
/// necesidad de una columna nueva ni de una migración.
final RegExp _iconKeyPattern = RegExp(r'^[A-Za-z0-9_\- ]+$');

/// `true` si lo guardado en `categories.icon` es un emoji y no una clave del
/// catálogo [kCategoryIcons]. Un valor nulo, vacío o una clave desconocida
/// siguen resolviéndose como ícono Material (ver [iconFromName]).
bool isEmojiIcon(String? value) {
  if (value == null || value.isEmpty) return false;
  return !_iconKeyPattern.hasMatch(value);
}

/// Opacidad del círculo de fondo de una categoría. Un ícono Material va en
/// blanco sobre el color casi sólido ([solid]); un emoji ya trae sus propios
/// colores, así que va sobre un tinte suave del color de la categoría.
double categoryIconBackgroundAlpha(String? icon, {double solid = 0.85}) {
  return isEmojiIcon(icon) ? 0.25 : solid;
}

/// Dibuja el ícono de una categoría, sea un ícono Material del catálogo o
/// un emoji. [color] solo aplica a los íconos Material: los emojis conservan sus
/// colores originales.
class CategoryGlyph extends StatelessWidget {
  /// Valor de `categories.icon`.
  final String? icon;
  final double size;
  final Color? color;

  const CategoryGlyph({
    super.key,
    required this.icon,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final value = icon;
    if (value != null && isEmojiIcon(value)) {
      // El glifo de un emoji suele salir un poco más ancho que su fontSize,
      // y varía según la plataforma: FittedBox lo encaja en size × size.
      return SizedBox.square(
        dimension: size,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: size, height: 1),
          ),
        ),
      );
    }
    return Icon(iconFromName(icon), size: size, color: color);
  }
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
