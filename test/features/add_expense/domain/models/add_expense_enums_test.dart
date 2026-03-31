import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';

void main() {
  group('SplitMode Enum Test', () {
    test('displayName returns correct string for equal', () {
      expect(SplitMode.equal.displayName, 'Equal Split');
    });

    test('displayName returns correct string for exact', () {
      expect(SplitMode.exact.displayName, 'Exact Amounts');
    });

    test('displayName returns correct string for percent', () {
      expect(SplitMode.percent.displayName, 'Percentages');
    });

    test('displayName returns correct string for shares', () {
      expect(SplitMode.shares.displayName, 'Shares');
    });
  });
}
