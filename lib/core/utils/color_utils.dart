import 'package:flutter/material.dart';

class ColorUtils {
  /// Converts a hex color string (like "#FF00FF" or "FF00FF") to a Color object.
  /// Defaults to Colors.grey if parsing fails or input is invalid.
  static Color fromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      if (buffer.length == 8) {
        return Color(int.parse(buffer.toString(), radix: 16));
      }
    } catch (e) {
      // Log error if needed
      // print('Error parsing hex color $hexString: $e');
    }
    return Colors.grey; // Default fallback color
  }

  /// Converts a Color object to a hex string (e.g., "#FF00FF").
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
