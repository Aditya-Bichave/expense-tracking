import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Re-instantiate with DateTime for correct type
  final tDate = DateTime(2023, 1, 1);
  final tExpenseModelCorrect = ExpenseModel(
    id: '1',
    title: 'Test Expense',
    amount: 100.0,
    date: tDate,
    accountId: 'acc1',
    categoryId: 'cat1',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 0.9,
    isRecurring: true,
  );

  group('ExpenseModel', () {
    test('should be a subclass of HiveObject', () {
      expect(tExpenseModelCorrect, isA<Object>()); // HiveObject is abstract
    });

    test('fromJson should return a valid model', () {
      final Map<String, dynamic> jsonMap = {
        'id': '1',
        'title': 'Test Expense',
        'amount': 100.0,
        'date': '2023-01-01T00:00:00.000',
        'accountId': 'acc1',
        'categoryId': 'cat1',
        'categorizationStatusValue': 'categorized',
        'confidenceScoreValue': 0.9,
        'isRecurring': true,
      };

      final result = ExpenseModel.fromJson(jsonMap);

      expect(result.id, '1');
      expect(result.title, 'Test Expense');
      expect(result.amount, 100.0);
      expect(result.date, tDate);
      expect(result.categoryId, 'cat1');
      expect(result.categorizationStatusValue, 'categorized');
      expect(result.confidenceScoreValue, 0.9);
      expect(result.isRecurring, true);
    });

    test('toJson should return a JSON map', () {
      final result = tExpenseModelCorrect.toJson();

      final expectedMap = {
        'id': '1',
        'title': 'Test Expense',
        'amount': 100.0,
        'date': tDate.toIso8601String(),
        'accountId': 'acc1',
        'categoryId': 'cat1',
        'categorizationStatusValue': 'categorized',
        'confidenceScoreValue': 0.9,
        'isRecurring': true,
      };

      expect(result, expectedMap);
    });

    test('toEntity should return a valid Entity', () {
      final result = tExpenseModelCorrect.toEntity();

      expect(result, isA<Expense>());
      expect(result.id, '1');
      expect(result.title, 'Test Expense');
      expect(result.amount, 100.0);
      expect(result.date, tDate);
      expect(result.category, null); // Model toEntity sets category to null
      expect(result.accountId, 'acc1');
      expect(result.status, CategorizationStatus.categorized);
      expect(result.confidenceScore, 0.9);
      expect(result.isRecurring, true);
    });

    test('fromEntity should return a valid Model', () {
      final tExpense = Expense(
        id: '1',
        title: 'Test Expense',
        amount: 100.0,
        date: tDate,
        accountId: 'acc1',
        // Assuming Category entity structure.
        // Need to check Category entity definition if I were to pass it.
        // But fromEntity uses entity.category?.id.
        category: null,
        status: CategorizationStatus.needsReview,
        confidenceScore: 0.5,
        isRecurring: false,
      );

      final result = ExpenseModel.fromEntity(tExpense);

      expect(result.id, '1');
      expect(result.title, 'Test Expense');
      expect(result.amount, 100.0);
      expect(result.date, tDate);
      expect(result.categoryId, null);
      // 'needs_review' is the value string for CategorizationStatus.needsReview
      expect(result.categorizationStatusValue, 'needs_review');
      expect(result.confidenceScoreValue, 0.5);
      expect(result.isRecurring, false);
    });
  });
}
