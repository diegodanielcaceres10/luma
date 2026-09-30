import 'package:flutter/material.dart';

Color colorFromHex(String? hex, {Color fallback = Colors.grey}) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse('ff$cleaned', radix: 16);
  return value != null ? Color(value) : fallback;
}

String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

const List<String> kCategoryColors = [
  '#4CBB7A', // authAccent (brand green)
  '#4F46E5', // indigo
  '#0EA5E9', // sky
  '#8B5CF6', // violet
  '#EC4899', // pink
  '#F59E0B', // amber
  '#EF6F5B', // authExpense (coral)
  '#94A3B8', // neutral gray
];
