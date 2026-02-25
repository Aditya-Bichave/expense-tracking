import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseModel', () {
    test('toRpcJson generates correct payload', () {
      final model = ExpenseModel(
        id: '123',
        title: 'Dinner',
        amount: 100.00,
        date: DateTime(2023, 10, 27, 12, 0, 0),
        accountId: 'acc1',
        groupId: 'grp1',
        createdBy: 'user1',
        currency: 'USD',
        notes: 'Yummy',
        payers: [
          const ExpensePayer(userId: 'user1', amountPaid: 80.00),
          const ExpensePayer(userId: 'user2', amountPaid: 20.00),
        ],
        splits: [
          const ExpenseSplit(
            userId: 'user1',
            shareType: SplitType.percent,
            shareValue: 80,
            computedAmount: 80.00,
          ),
          const ExpenseSplit(
            userId: 'user2',
            shareType: SplitType.percent,
            shareValue: 20,
            computedAmount: 20.00,
          ),
        ],
      );

      final json = model.toRpcJson();

      expect(json['p_group_id'], 'grp1');
      expect(json['p_created_by'], 'user1');
      expect(json['p_amount_total'], 100.00);
      expect(json['p_currency'], 'USD');
      expect(json['p_description'], 'Dinner');
      expect(json['p_notes'], 'Yummy');
      expect(json['p_expense_date'], isNotNull);

      final payers = json['p_payers'] as List;
      expect(payers.length, 2);
      expect(payers[0]['user_id'], 'user1');
      expect(payers[0]['amount_paid'], 80.00);

      final splits = json['p_splits'] as List;
      expect(splits.length, 2);
      expect(splits[0]['user_id'], 'user1');
      expect(splits[0]['share_type'], 'PERCENT');
      expect(splits[0]['share_value'], 80.0);
      expect(splits[0]['computed_amount'], 80.00);
    });
  });
}
