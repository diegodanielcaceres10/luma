import 'package:flutter/material.dart';

/// Catálogo fijo de íconos disponibles para cuentas. Fuente única de verdad
/// para el picker del formulario y el mapeo de `accounts.icon` -> IconData.
const Map<String, IconData> kAccountIcons = {
  'wallet': Icons.account_balance_wallet_rounded,
  'bank': Icons.account_balance_rounded,
  'cash': Icons.payments_rounded,
  'card': Icons.credit_card_rounded,
  'savings': Icons.savings_rounded,
  'other': Icons.more_horiz_rounded,
};

/// Mapea el nombre de icono guardado en `accounts.icon` a un IconData.
IconData accountIconFromName(String? name) {
  if (name == null) return kAccountIcons['wallet']!;
  return kAccountIcons[name] ?? kAccountIcons['wallet']!;
}

/// Monedas soportadas por el picker del formulario de cuentas.
const List<String> kAccountCurrencies = [
  'USD',
  'EUR',
  'ARS',
  'MXN',
  'COP',
  'CLP',
  'PEN',
  'BRL',
];
