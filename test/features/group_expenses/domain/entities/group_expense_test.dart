import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupExpense', () {
    test('supports value equality', () {
      final tPayer = ExpensePayer(userId: 'u1', amount: 50);
      final tSplit = ExpenseSplit(
        userId: 'u1',
        amount: 50,
        splitType: SplitType.equal,
      );

      final expense1 = GroupExpense(
        id: '1',
        groupId: 'g1',
        createdBy: 'c1',
        title: 'Dinner',
        amount: 100,
        currency: 'USD',
        occurredAt: DateTime(2023, 10, 27, 10, 0),
        createdAt: DateTime(2023, 10, 27, 10, 0),
        updatedAt: DateTime(2023, 10, 27, 10, 0),
        payers: [tPayer],
        splits: [tSplit],
      );

      final expense2 = GroupExpense(
        id: '1',
        groupId: 'g1',
        createdBy: 'c1',
        title: 'Dinner',
        amount: 100,
        currency: 'USD',
        occurredAt: DateTime(2023, 10, 27, 10, 0),
        createdAt: DateTime(2023, 10, 27, 10, 0),
        updatedAt: DateTime(2023, 10, 27, 10, 0),
        payers: [tPayer],
        splits: [tSplit],
      );

      expect(expense1, equals(expense2));
    });
  });
}
