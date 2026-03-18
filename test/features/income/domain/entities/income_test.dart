import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';

void main() {
  test('Income entity creation and equality', () {
    final tDate = DateTime(2023, 1, 1);
    final income1 = Income(
      id: '1',
      title: 'title',
      amount: 100,
      date: tDate,
      accountId: 'a1',
    );
    final income2 = Income(
      id: '1',
      title: 'title',
      amount: 100,
      date: tDate,
      accountId: 'a1',
    );
    final income3 = Income(
      id: '2',
      title: 'title',
      amount: 100,
      date: tDate,
      accountId: 'a1',
    );
    expect(income1, equals(income2));
    expect(income1, isNot(equals(income3)));
  });
}
