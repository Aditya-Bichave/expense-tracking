import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tCategory = Category(
    id: 'cat1',
    name: 'Salary',
    iconName: 'money',
    colorHex: '#00FF00',
    type: CategoryType.income,
    isCustom: false,
  );

  final tIncome = Income(
    id: '1',
    title: 'Monthly Salary',
    amount: 5000.0,
    date: tDate,
    category: tCategory,
    accountId: 'acc1',
    notes: 'Test notes',
    status: CategorizationStatus.categorized,
    confidenceScore: 0.9,
    merchantId: 'merch1',
    isRecurring: true,
  );

  group('Income', () {
    test('should assign properties correctly', () {
      expect(tIncome.id, '1');
      expect(tIncome.title, 'Monthly Salary');
      expect(tIncome.amount, 5000.0);
      expect(tIncome.date, tDate);
      expect(tIncome.category, tCategory);
      expect(tIncome.accountId, 'acc1');
      expect(tIncome.notes, 'Test notes');
      expect(tIncome.status, CategorizationStatus.categorized);
      expect(tIncome.confidenceScore, 0.9);
      expect(tIncome.merchantId, 'merch1');
      expect(tIncome.isRecurring, true);
    });

    test('should return correct props for Equatable', () {
      final props = tIncome.props;
      expect(props, [
        '1',
        'Monthly Salary',
        5000.0,
        tDate,
        tCategory,
        'acc1',
        'Test notes',
        CategorizationStatus.categorized,
        0.9,
        'merch1',
        true,
      ]);
    });

    group('copyWith', () {
      test('should return a new object with updated properties', () {
        final newDate = DateTime(2023, 2, 1);
        final newCategory = Category(
          id: 'cat2',
          name: 'Bonus',
          iconName: 'money',
          colorHex: '#0000FF',
          type: CategoryType.income,
          isCustom: false,
        );

        final updatedIncome = tIncome.copyWith(
          id: '2',
          title: 'Yearly Bonus',
          amount: 10000.0,
          date: newDate,
          category: newCategory,
          accountId: 'acc2',
          notes: 'New notes',
          status: CategorizationStatus.uncategorized,
          confidenceScore: 0.5,
          merchantId: 'merch2',
          isRecurring: false,
        );

        expect(updatedIncome.id, '2');
        expect(updatedIncome.title, 'Yearly Bonus');
        expect(updatedIncome.amount, 10000.0);
        expect(updatedIncome.date, newDate);
        expect(updatedIncome.category, newCategory);
        expect(updatedIncome.accountId, 'acc2');
        expect(updatedIncome.notes, 'New notes');
        expect(updatedIncome.status, CategorizationStatus.uncategorized);
        expect(updatedIncome.confidenceScore, 0.5);
        expect(updatedIncome.merchantId, 'merch2');
        expect(updatedIncome.isRecurring, false);
      });

      test('should retain original properties when not provided', () {
        final updatedIncome = tIncome.copyWith();
        expect(updatedIncome, tIncome);
      });

      test('should correctly nullify optional properties when explicitly requested via ValueGetter', () {
        final updatedIncome = tIncome.copyWith(
          categoryOrNull: () => null,
          notesOrNull: () => null,
          confidenceScoreOrNull: () => null,
          merchantIdOrNull: () => null,
        );

        expect(updatedIncome.category, isNull);
        expect(updatedIncome.notes, isNull);
        expect(updatedIncome.confidenceScore, isNull);
        expect(updatedIncome.merchantId, isNull);

        // Other properties should remain unchanged
        expect(updatedIncome.id, '1');
        expect(updatedIncome.title, 'Monthly Salary');
        expect(updatedIncome.amount, 5000.0);
      });
    });
  });
}
