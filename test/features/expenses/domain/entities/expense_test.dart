import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategory extends Mock implements Category {}

void main() {
  final tDate = DateTime(2023, 10, 26, 12, 0, 0);
  final tCategory = MockCategory();

  final tExpense = Expense(
    id: '1',
    title: 'Groceries',
    amount: 100.0,
    date: tDate,
    category: tCategory,
    accountId: 'acc1',
    status: CategorizationStatus.categorized,
    confidenceScore: 0.9,
    merchantId: 'merch1',
    isRecurring: false,
  );

  group('Expense', () {
    test('supports value comparisons', () {
      final tExpense2 = Expense(
        id: '1',
        title: 'Groceries',
        amount: 100.0,
        date: tDate,
        category: tCategory,
        accountId: 'acc1',
        status: CategorizationStatus.categorized,
        confidenceScore: 0.9,
        merchantId: 'merch1',
        isRecurring: false,
      );
      expect(tExpense, tExpense2);
    });

    test('props are correct', () {
      expect(tExpense.props, [
        '1',
        'Groceries',
        100.0,
        tDate,
        tCategory,
        'acc1',
        CategorizationStatus.categorized,
        0.9,
        'merch1',
        false,
      ]);
    });

    group('copyWith', () {
      test('should return a new instance with updated values', () {
        final result = tExpense.copyWith(amount: 200.0);
        expect(result.amount, 200.0);
        expect(result.id, tExpense.id);
      });

      test('should allow setting nullable fields to null', () {
        final result = tExpense.copyWith(
          categoryOrNull: () => null,
          confidenceScoreOrNull: () => null,
          merchantIdOrNull: () => null,
        );
        expect(result.category, isNull);
        expect(result.confidenceScore, isNull);
        expect(result.merchantId, isNull);
      });

      test('should update nested category', () {
        final newCategory = MockCategory();
        final result = tExpense.copyWith(category: newCategory);
        expect(result.category, newCategory);
      });
    });
  });
}
