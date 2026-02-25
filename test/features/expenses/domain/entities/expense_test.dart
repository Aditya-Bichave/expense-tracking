import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense', () {
    final tDate = DateTime(2023, 10, 27);
    const tPayer = ExpensePayer(userId: 'user1', amountPaid: 100.00);
    const tSplit = ExpenseSplit(
      userId: 'user1',
      shareType: SplitType.equal,
      shareValue: 1,
      computedAmount: 100.00,
    );
    const tCategory = Category(
      id: 'cat1',
      name: 'Food',
      iconName: 'food',
      colorHex: '0xFFFFFF',
      type: CategoryType.expense,
      isCustom: false,
    );

    final tExpense = Expense(
      id: '1',
      title: 'Dinner',
      amount: 100.00,
      date: tDate,
      accountId: 'acc1',
      category: tCategory,
      status: CategorizationStatus.categorized,
      confidenceScore: 0.9,
      isRecurring: true,
      merchantId: 'merch1',
      groupId: 'grp1',
      createdBy: 'user1',
      currency: 'USD',
      notes: 'Yummy',
      payers: const [tPayer],
      splits: const [tSplit],
    );

    test('supports value equality', () {
      final tExpense2 = Expense(
        id: '1',
        title: 'Dinner',
        amount: 100.00,
        date: tDate,
        accountId: 'acc1',
        category: tCategory,
        status: CategorizationStatus.categorized,
        confidenceScore: 0.9,
        isRecurring: true,
        merchantId: 'merch1',
        groupId: 'grp1',
        createdBy: 'user1',
        currency: 'USD',
        notes: 'Yummy',
        payers: const [tPayer],
        splits: const [tSplit],
      );

      expect(tExpense, equals(tExpense2));
    });

    test('copyWith updates fields', () {
      final updated = tExpense.copyWith(
        title: 'Lunch',
        amount: 50.00,
        groupId: 'grp2',
        notes: 'Okay',
      );

      expect(updated.title, 'Lunch');
      expect(updated.amount, 50.00);
      expect(updated.groupId, 'grp2');
      expect(updated.notes, 'Okay');
      expect(updated.id, tExpense.id); // Unchanged
    });

    test('copyWith can clear nullable fields', () {
      final updated = tExpense.copyWith(
        categoryOrNull: () => null,
        confidenceScoreOrNull: () => null,
        merchantIdOrNull: () => null,
        groupIdOrNull: () => null,
        notesOrNull: () => null,
      );

      expect(updated.category, isNull);
      expect(updated.confidenceScore, isNull);
      expect(updated.merchantId, isNull);
      expect(updated.groupId, isNull);
      expect(updated.notes, isNull);
    });
  });
}
