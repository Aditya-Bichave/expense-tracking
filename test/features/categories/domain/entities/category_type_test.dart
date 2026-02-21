import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';

void main() {
  group('CategoryType', () {
    test('toJson should return enum name', () {
      expect(CategoryType.expense.toJson(), 'expense');
      expect(CategoryType.income.toJson(), 'income');
    });

    test('fromJson should return correct enum', () {
      expect(CategoryTypeExtension.fromJson('expense'), CategoryType.expense);
      expect(CategoryTypeExtension.fromJson('income'), CategoryType.income);
    });

    test('fromJson should return default (expense) for unknown string', () {
      expect(CategoryTypeExtension.fromJson('unknown'), CategoryType.expense);
    });
  });
}
