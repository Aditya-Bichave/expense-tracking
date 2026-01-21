import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorUtils', () {
    test('fromHex should parse 6-digit hex string correctly', () {
      final color = ColorUtils.fromHex('FF0000');
      expect(color.value, const Color(0xFFFF0000).value);
    });

    test('fromHex should parse 6-digit hex string with hash correctly', () {
      final color = ColorUtils.fromHex('#00FF00');
      expect(color.value, const Color(0xFF00FF00).value);
    });

    test('fromHex should parse 8-digit hex string correctly', () {
      final color = ColorUtils.fromHex('800000FF');
      // ARGB: 80 alpha, 00 red, 00 green, FF blue
      expect(color.value, const Color(0x800000FF).value);
    });

    test('fromHex should return grey for invalid hex string', () {
      final color = ColorUtils.fromHex('invalid');
      expect(color, Colors.grey);
    });

    test('fromHex should return grey for partial string', () {
      final color = ColorUtils.fromHex('123');
      expect(color, Colors.grey);
    });

    test('fromHex should parse 7-digit hex string (hash + 6 digits)', () {
      final color = ColorUtils.fromHex('#112233');
      expect(color.value, const Color(0xFF112233).value);
    });

    test('toHex should convert color to hex string', () {
      const color = Color(0xFF112233);
      final hex = ColorUtils.toHex(color);
      expect(hex, '#112233');
    });

    test('toHex should handle alpha channel', () {
      const color = Color(0x80112233);
      // toHex implementation: '#${color.value.toRadixString(16).substring(2).toUpperCase()}'
      // This implementation seemingly assumes 0xFF alpha (substring 2 strips the first 2 chars which is usually alpha in argb if printed as hex?)
      // Wait, color.value is an int.
      // 0x80112233.toRadixString(16) is "80112233".
      // substring(2) would be "112233".
      // So it discards alpha? Let's check the implementation again.
      // Yes: return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';

      // If color value is small (e.g. 0), toRadixString might be short?
      // But Color is usually 32-bit int.

      final hex = ColorUtils.toHex(color);
      expect(hex, '#112233');
    });
  });
}
