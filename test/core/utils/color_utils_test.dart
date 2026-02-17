import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColorUtils', () {
    group('fromHex', () {
      test('parses 6-digit hex string correctly', () {
        expect(ColorUtils.fromHex('FF0000'), const Color(0xFFFF0000));
        expect(ColorUtils.fromHex('00FF00'), const Color(0xFF00FF00));
        expect(ColorUtils.fromHex('0000FF'), const Color(0xFF0000FF));
      });

      test('parses 7-digit hex string (with #) correctly', () {
        expect(ColorUtils.fromHex('#FF0000'), const Color(0xFFFF0000));
        expect(ColorUtils.fromHex('#00FF00'), const Color(0xFF00FF00));
      });

      test('parses 8-digit hex string (with alpha) correctly', () {
        // The implementation adds 'ff' if length is 6 or 7.
        // If I pass 8 digits (no #), it might work if the implementation supports it.
        // Let's check implementation again.
        // if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
        // buffer.write(hexString.replaceFirst('#', ''));
        // If I pass '80FF0000' (length 8), it writes '80FF0000'. Length is 8. Parsed as int.
        expect(ColorUtils.fromHex('80FF0000'), const Color(0x80FF0000));
      });

      test('parses 9-digit hex string (with # and alpha) correctly', () {
        // '#80FF0000'. Length 9.
        // buffer writes '80FF0000'. Length 8. OK.
        expect(ColorUtils.fromHex('#80FF0000'), const Color(0x80FF0000));
      });

      test('returns Colors.grey for invalid hex string', () {
        expect(ColorUtils.fromHex('INVALID'), Colors.grey);
        expect(ColorUtils.fromHex('123'), Colors.grey); // Too short
        expect(ColorUtils.fromHex(''), Colors.grey); // Empty
      });

      test(
        'returns Colors.grey for null-ish input (though param is non-nullable String)',
        () {
          // Dart strong mode prevents passing null usually, but we can test unexpected strings
          expect(ColorUtils.fromHex('ZZZZZZ'), Colors.grey); // Non-hex chars
        },
      );
    });

    group('toHex', () {
      test('converts Color to hex string correctly', () {
        expect(ColorUtils.toHex(const Color(0xFFFF0000)), '#FF0000');
        expect(ColorUtils.toHex(const Color(0xFF00FF00)), '#00FF00');
        expect(ColorUtils.toHex(const Color(0xFF0000FF)), '#0000FF');
      });

      test('converts Color with transparency correctly', () {
        // Implementation: '#${color.value.toRadixString(16).substring(2).toUpperCase()}'
        // If color is 0x80FF0000. value is negative as signed int? No, Color value is 32-bit int.
        // toRadixString(16) might return '80ff0000'. substring(2) -> 'ff0000'.
        // Wait, if alpha is present, does it strip it?
        // 0xFFFF0000 -> ffff0000 -> ff0000. Correct.
        // 0x80FF0000 -> 80ff0000 -> ff0000.
        // It seems toHex strips the alpha channel (first 2 chars)!
        // Let's verify this behavior.

        // 0x80FF0000. toRadixString(16) is '80ff0000'. substring(2) is 'ff0000'.
        // So it IGNORES alpha.
        expect(ColorUtils.toHex(const Color(0x80FF0000)), '#FF0000');
      });
    });
  });
}
