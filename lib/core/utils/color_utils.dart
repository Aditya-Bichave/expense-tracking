import 'package:flutter/material.dart';

class ColorUtils {
  /// Converts a hex color string (like "#FF00FF" or "FF00FF") to a Color object.
  /// Defaults to Colors.grey if parsing fails or input is invalid.
  static Color fromHex(String? hexString) {
    if (hexString == null) return Colors.grey;
    String cleanHex = hexString.replaceFirst('#', '');
    final buffer = StringBuffer();
    if (cleanHex.length == 6) buffer.write('ff');
    buffer.write(cleanHex);
    if (buffer.length == 8) {
      int? val = int.tryParse(buffer.toString(), radix: 16);
      if (val != null) {
        return Color(val);
      }
    }
    return Colors.grey; // Default fallback color
  }

  /// Converts a Color object to a hex string (e.g., "#FF00FF").
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
