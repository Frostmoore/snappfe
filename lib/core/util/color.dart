import 'package:flutter/material.dart';

/// Converte una stringa hex ('#RRGGBB', 'RRGGBB', '#AARRGGBB') in [Color].
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h'; // aggiunge alpha pieno
  if (h.length != 8) return null;
  final value = int.tryParse(h, radix: 16);
  return value == null ? null : Color(value);
}
