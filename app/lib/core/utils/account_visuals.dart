import 'package:flutter/material.dart';

/// Ícono único para todas las cuentas. Se removió el picker por cuenta
/// (campo `accounts.icon` eliminado); si en el futuro hace falta
/// diferenciarlas visualmente, se retoma acá.
const IconData kDefaultAccountIcon = Icons.account_balance_wallet_rounded;

/// Monedas soportadas — hoy sin uso en el formulario de cuentas (se
/// removió `accounts.currency`), se deja lista para cuando la moneda pase
/// a ser una configuración a nivel usuario.
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
