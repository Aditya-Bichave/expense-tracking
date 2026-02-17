import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Test Income',
    amount: 1000.0,
    date: tDate,
    accountId: 'acc1',
    categoryId: 'cat1',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 0.9,
    isRecurring: true,
    notes: 'Test note',
  );

  group('IncomeModel', () {
    test('should be a subclass of HiveObject', () {
      expect(tIncomeModel, isA<Object>());
    });

    test('fromJson should return a valid model', () {
      final Map<String, dynamic> jsonMap = {
        'id': '1',
        'title': 'Test Income',
        'amount': 1000.0,
        'date': tDate.toIso8601String(),
        'accountId': 'acc1',
        'categoryId': 'cat1',
        'categorizationStatusValue': 'categorized',
        'confidenceScoreValue': 0.9,
        'isRecurring': true,
        'notes': 'Test note',
      };

      final result = IncomeModel.fromJson(jsonMap);

      expect(result.id, '1');
      expect(result.title, 'Test Income');
      expect(result.amount, 1000.0);
      expect(result.date, tDate);
      expect(result.categoryId, 'cat1');
      expect(result.categorizationStatusValue, 'categorized');
      expect(result.confidenceScoreValue, 0.9);
      expect(result.isRecurring, true);
      expect(result.notes, 'Test note');
    });

    test('toJson should return a JSON map', () {
      final result = tIncomeModel.toJson();

      final expectedMap = {
        'id': '1',
        'title': 'Test Income',
        'amount': 1000.0,
        'date': tDate.toIso8601String(),
        'accountId': 'acc1',
        'categoryId': 'cat1',
        'categorizationStatusValue': 'categorized',
        'confidenceScoreValue': 0.9,
        'isRecurring': true,
        'notes': 'Test note',
      };

      expect(result, expectedMap);
    });

    test('toEntity should return a valid Entity', () {
      final result = tIncomeModel.toEntity();

      expect(result, isA<Income>());
      expect(result.id, '1');
      expect(result.title, 'Test Income');
      expect(result.amount, 1000.0);
      expect(result.date, tDate);
      expect(result.category, null);
      expect(result.accountId, 'acc1');
      expect(result.status, CategorizationStatus.categorized);
      expect(result.confidenceScore, 0.9);
      expect(result.isRecurring, true);
      expect(result.notes, 'Test note');
    });

    test('fromEntity should return a valid Model', () {
      final tIncome = Income(
        id: '1',
        title: 'Test Income',
        amount: 1000.0,
        date: tDate,
        accountId: 'acc1',
        category: null,
        status: CategorizationStatus.uncategorized,
        confidenceScore: null,
        isRecurring: false,
        notes: 'Test note',
      );

      final result = IncomeModel.fromEntity(tIncome);

      expect(result.id, '1');
      expect(result.title, 'Test Income');
      expect(result.amount, 1000.0);
      expect(result.date, tDate);
      expect(result.categoryId, null);
      expect(result.categorizationStatusValue, 'uncategorized');
      expect(result.confidenceScoreValue, null);
      expect(result.isRecurring, false);
      expect(result.notes, 'Test note');
    });
  });
}
