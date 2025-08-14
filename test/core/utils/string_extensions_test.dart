import 'package:expense_tracker/core/utils/string_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringCapitalization.capitalize', () {
    test('capitalizes first letter of lowercase word', () {
      expect('hello'.capitalize(), 'Hello');
    });

    test('returns empty string unchanged', () {
      expect(''.capitalize(), '');
    });
  });
}
