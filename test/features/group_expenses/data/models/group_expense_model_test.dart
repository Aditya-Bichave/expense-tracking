import 'dart:convert';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tPayer = ExpensePayer(userId: 'u1', amount: 50);
  final tSplit = ExpenseSplit(
    userId: 'u1',
    amount: 50,
    splitType: SplitType.equal,
  );

  final tExpense = GroupExpense(
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

  final tExpenseModel = GroupExpenseModel(
    id: '1',
    groupId: 'g1',
    createdBy: 'c1',
    title: 'Dinner',
    amount: 100,
    currency: 'USD',
    occurredAt: DateTime(2023, 10, 27, 10, 0),
    createdAt: DateTime(2023, 10, 27, 10, 0),
    updatedAt: DateTime(2023, 10, 27, 10, 0),
    payers: [ExpensePayerModel(userId: 'u1', amount: 50)],
    splits: [
      ExpenseSplitModel(userId: 'u1', amount: 50, splitTypeValue: 'equal'),
    ],
  );

  group('GroupExpenseModel', () {
    test('toEntity should return a valid entity', () async {
      final result = tExpenseModel.toEntity();
      expect(result, tExpense);
    });

    test('fromEntity should return a valid model', () async {
      final result = GroupExpenseModel.fromEntity(tExpense);
      expect(result.id, tExpenseModel.id);
      expect(result.groupId, tExpenseModel.groupId);
      expect(result.payers.first.userId, tExpenseModel.payers.first.userId);
      expect(
        result.splits.first.splitTypeValue,
        tExpenseModel.splits.first.splitTypeValue,
      );
    });

    test('fromJson should return a valid model', () async {
      final Map<String, dynamic> jsonMap = {
        'id': '1',
        'group_id': 'g1',
        'created_by': 'c1',
        'title': 'Dinner',
        'amount': 100.0,
        'currency': 'USD',
        'occurred_at': '2023-10-27T10:00:00.000',
        'created_at': '2023-10-27T10:00:00.000',
        'updated_at': '2023-10-27T10:00:00.000',
        'payers': [
          {'userId': 'u1', 'amount': 50.0},
        ],
        'splits': [
          {'userId': 'u1', 'amount': 50.0, 'splitTypeValue': 'equal'},
        ],
      };

      final result = GroupExpenseModel.fromJson(jsonMap);
      expect(result.id, tExpenseModel.id);
      expect(result.amount, tExpenseModel.amount);
      expect(result.payers.length, 1);
    });

    test(
      'toJson should return a JSON map containing the proper data',
      () async {
        final result = tExpenseModel.toJson();
        final decoded = jsonDecode(jsonEncode(result));

        final expectedMap = {
          'id': '1',
          'group_id': 'g1',
          'created_by': 'c1',
          'title': 'Dinner',
          'amount': 100.0,
          'currency': 'USD',
          'occurred_at': '2023-10-27T10:00:00.000',
          'created_at': '2023-10-27T10:00:00.000',
          'updated_at': '2023-10-27T10:00:00.000',
          'payers': [
            {'userId': 'u1', 'amount': 50.0},
          ],
          'splits': [
            {'userId': 'u1', 'amount': 50.0, 'splitTypeValue': 'equal'},
          ],
        };
        expect(decoded, expectedMap);
      },
    );
  });
}
