import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('fr_FR', null);
  });

  test('formats date according to locale', () {
    final date = DateTime(2024, 1, 5, 15, 30);

    final us = DateFormatter.formatDate(date, locale: 'en_US');
    final fr = DateFormatter.formatDate(date, locale: 'fr_FR');
    expect(us, isNot(equals(fr)));

    final usDateTime = DateFormatter.formatDateTime(date, locale: 'en_US');
    final frDateTime = DateFormatter.formatDateTime(date, locale: 'fr_FR');
    expect(usDateTime, isNot(equals(frDateTime)));
  });
}
