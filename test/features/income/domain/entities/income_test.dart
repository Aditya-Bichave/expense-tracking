import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tIncome = Income(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: DateTime.fromMillisecondsSinceEpoch(0),
    accountId: 'acc1',
    category: const Category(
      id: 'cat1',
      name: 'Salary',
      iconName: 'work',
      colorHex: '#000000',
      type: CategoryType.income,
      isCustom: false,
    ),
    notes: 'Monthly salary',
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
    isRecurring: true,
  );

  group('Income Entity', () {
    test('supports value comparisons', () {
      final tIncome2 = Income(
        id: '1',
        title: 'Salary',
        amount: 5000.0,
        date: DateTime.fromMillisecondsSinceEpoch(0),
        accountId: 'acc1',
        category: const Category(
          id: 'cat1',
          name: 'Salary',
          iconName: 'work',
          colorHex: '#000000',
          type: CategoryType.income,
          isCustom: false,
        ),
        notes: 'Monthly salary',
        status: CategorizationStatus.categorized,
        confidenceScore: 1.0,
        isRecurring: true,
      );
      expect(tIncome, equals(tIncome2));
    });

    group('copyWith', () {
      test('returns same object if no arguments are provided', () {
        expect(tIncome.copyWith(), equals(tIncome));
      });

      test('replaces every non-null parameter', () {
        const tNewCategory = Category(
          id: 'cat2',
          name: 'Bonus',
          iconName: 'card_giftcard',
          colorHex: '#00FF00',
          type: CategoryType.income,
          isCustom: false,
        );
        final tNewDate = DateTime.fromMillisecondsSinceEpoch(1000);

        final result = tIncome.copyWith(
          id: '2',
          title: 'Bonus',
          amount: 1000.0,
          date: tNewDate,
          category: tNewCategory,
          accountId: 'acc2',
          notes: 'Yearly bonus',
          status: CategorizationStatus.categorized,
          confidenceScore: 0.9,
          isRecurring: false,
        );

        expect(
          result,
          equals(
            Income(
              id: '2',
              title: 'Bonus',
              amount: 1000.0,
              date: tNewDate,
              category: tNewCategory,
              accountId: 'acc2',
              notes: 'Yearly bonus',
              status: CategorizationStatus.categorized,
              confidenceScore: 0.9,
              isRecurring: false,
            ),
          ),
        );
      });

      test('clears nullable fields when using ValueGetter', () {
        final result = tIncome.copyWith(
          categoryOrNull: () => null,
          notesOrNull: () => null,
          confidenceScoreOrNull: () => null,
        );

        expect(result.category, isNull);
        expect(result.notes, isNull);
        expect(result.confidenceScore, isNull);
        // Verify other fields remain unchanged
        expect(result.id, equals(tIncome.id));
        expect(result.title, equals(tIncome.title));
      });
    });
  });
}
