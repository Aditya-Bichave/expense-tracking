import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseModel', () {
    final tDate = DateTime(2023, 10, 27, 12, 0, 0);
    const tPayer = ExpensePayer(userId: 'user1', amountPaid: 100.00);
    const tSplit = ExpenseSplit(
      userId: 'user1',
      shareType: SplitType.equal,
      shareValue: 1,
      computedAmount: 100.00,
    );

    final tExpenseModel = ExpenseModel(
      id: '123',
      title: 'Dinner',
      amount: 100.00,
      date: tDate,
      accountId: 'acc1',
      categoryId: 'cat1',
      categorizationStatusValue: 'categorized',
      confidenceScoreValue: 0.9,
      isRecurring: true,
      merchantId: 'merch1',
      groupId: 'grp1',
      createdBy: 'user1',
      currency: 'USD',
      notes: 'Yummy',
      payers: [tPayer],
      splits: [tSplit],
    );

    final tExpenseEntity = Expense(
      id: '123',
      title: 'Dinner',
      amount: 100.00,
      date: tDate,
      accountId: 'acc1',
      // Category is not fully hydrated in fromEntity, only ID is used. But toEntity returns Expense with category=null.
      // Wait, fromEntity takes Expense (Entity). Does Entity contain Category?
      // Yes. ExpenseModel.fromEntity reads entity.category?.id.
      // So here we pass an entity WITH category.
      category: const Category(
        id: 'cat1',
        name: 'Food',
        iconName: 'food',
        colorHex: '0xFFFFFF',
        type: CategoryType.expense,
        isCustom: false,
      ),
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

    test('toRpcJson generates correct payload', () {
      final json = tExpenseModel.toRpcJson();

      expect(json['p_group_id'], 'grp1');
      expect(json['p_created_by'], 'user1');
      expect(json['p_amount_total'], 100.00);
      expect(json['p_currency'], 'USD');
      expect(json['p_description'], 'Dinner');
      expect(json['p_notes'], 'Yummy');
      expect(json['p_expense_date'], isNotNull);

      final payers = json['p_payers'] as List;
      expect(payers.length, 1);
      expect(payers[0]['user_id'], 'user1');
      expect(payers[0]['amount_paid'], 100.00);

      final splits = json['p_splits'] as List;
      expect(splits.length, 1);
      expect(splits[0]['user_id'], 'user1');
      expect(splits[0]['share_type'], 'EQUAL');
      expect(splits[0]['share_value'], 1.0);
      expect(splits[0]['computed_amount'], 100.00);
    });

    test('fromEntity creates correct model', () {
      final result = ExpenseModel.fromEntity(tExpenseEntity);

      expect(result.id, tExpenseModel.id);
      expect(result.title, tExpenseModel.title);
      expect(result.amount, tExpenseModel.amount);
      expect(result.date, tExpenseModel.date);
      expect(result.accountId, tExpenseModel.accountId);
      expect(result.categoryId, tExpenseModel.categoryId);
      expect(
        result.categorizationStatusValue,
        tExpenseModel.categorizationStatusValue,
      );
      expect(result.confidenceScoreValue, tExpenseModel.confidenceScoreValue);
      expect(result.isRecurring, tExpenseModel.isRecurring);
      expect(result.merchantId, tExpenseModel.merchantId);
      expect(result.groupId, tExpenseModel.groupId);
      expect(result.createdBy, tExpenseModel.createdBy);
      expect(result.currency, tExpenseModel.currency);
      expect(result.notes, tExpenseModel.notes);
      expect(result.payers, tExpenseModel.payers);
      expect(result.splits, tExpenseModel.splits);
    });

    test('toEntity creates correct entity', () {
      final result = tExpenseModel.toEntity();

      expect(result.id, tExpenseEntity.id);
      expect(result.title, tExpenseEntity.title);
      expect(result.amount, tExpenseEntity.amount);
      expect(result.date, tExpenseEntity.date);
      expect(result.accountId, tExpenseEntity.accountId);
      // Category is null in toEntity result as per implementation (hydrated later)
      expect(result.category, isNull);
      expect(result.status, tExpenseEntity.status);
      expect(result.confidenceScore, tExpenseEntity.confidenceScore);
      expect(result.isRecurring, tExpenseEntity.isRecurring);
      expect(result.merchantId, tExpenseEntity.merchantId);
      expect(result.groupId, tExpenseEntity.groupId);
      expect(result.createdBy, tExpenseEntity.createdBy);
      expect(result.currency, tExpenseEntity.currency);
      expect(result.notes, tExpenseEntity.notes);
      expect(result.payers, tExpenseEntity.payers);
      expect(result.splits, tExpenseEntity.splits);
    });
  });
}
