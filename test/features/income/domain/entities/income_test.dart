import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';

void main() {
  group('Income Test', () {
    final tDate = DateTime(2023, 1, 1);
    const tCategory = Category(
      id: 'c1',
      name: 'Salary',
      colorHex: '#FFFFFF',
      iconName: 'icon',
      type: CategoryType.income,
      isCustom: false,
    );

    final tIncome = Income(
      id: 'i1',
      title: 'Monthly Salary',
      amount: 5000.0,
      date: tDate,
      category: tCategory,
      accountId: 'a1',
      notes: 'Notes',
      status: CategorizationStatus.categorized,
      confidenceScore: 0.9,
      merchantId: 'm1',
      isRecurring: true,
    );

    test('should copyWith correctly', () {
      final updatedDate = DateTime(2023, 2, 1);
      final updated = tIncome.copyWith(
        title: 'Updated Salary',
        amount: 5500.0,
        date: updatedDate,
        isRecurring: false,
      );

      expect(updated.id, 'i1');
      expect(updated.title, 'Updated Salary');
      expect(updated.amount, 5500.0);
      expect(updated.date, updatedDate);
      expect(updated.isRecurring, false);
      expect(updated.category, tCategory);
    });

    test('should allow setting nullable fields to null via copyWith', () {
      final updated = tIncome.copyWith(
        notesOrNull: () => null,
        categoryOrNull: () => null,
        confidenceScoreOrNull: () => null,
        merchantIdOrNull: () => null,
      );

      expect(updated.notes, null);
      expect(updated.category, null);
      expect(updated.confidenceScore, null);
      expect(updated.merchantId, null);
      expect(updated.title, 'Monthly Salary');
    });

    test('props should contain all fields', () {
      expect(tIncome.props, [
        'i1',
        'Monthly Salary',
        5000.0,
        tDate,
        tCategory,
        'a1',
        'Notes',
        CategorizationStatus.categorized,
        0.9,
        'm1',
        true,
      ]);
    });
  });
}
