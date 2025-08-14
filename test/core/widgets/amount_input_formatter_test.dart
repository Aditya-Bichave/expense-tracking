import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextInputFormatter buildAmountFormatter() {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    final sanitized = newValue.text.replaceAll(RegExp('[^0-9.,]'), '');
    return newValue.copyWith(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  });
}

void main() {
  test('amount formatter allows multi-digit numbers', () {
    final formatter = buildAmountFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '222'),
    );
    expect(result.text, '222');
  });

  test('amount formatter strips invalid characters', () {
    final formatter = buildAmountFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '12a3'),
    );
    expect(result.text, '123');
  });
}
