import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tDate = DateTime.fromMillisecondsSinceEpoch(0);

  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: tDate,
    accountId: 'acc1',
    categoryId: 'cat1',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 1.0,
    isRecurring: true,
    notes: 'Notes',
  );

  final tIncomeEntity = Income(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: tDate,
    accountId: 'acc1',
    // category will be null when converted from model
    category: null,
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
    isRecurring: true,
    notes: 'Notes',
  );

  final tIncomeEntityWithCategory = tIncomeEntity.copyWith(
    category: const Category(
      id: 'cat1',
      name: 'Salary',
      iconName: 'work',
      colorHex: '#000000',
      type: CategoryType.income,
      isCustom: false,
    ),
  );

  group('IncomeModel', () {
    group('fromEntity', () {
      test('should return a valid model from entity with category', () {
        final result = IncomeModel.fromEntity(tIncomeEntityWithCategory);
        expect(result.id, tIncomeModel.id);
        expect(result.categoryId, 'cat1');
        expect(result.categorizationStatusValue, 'categorized');
      });

      test('should return a valid model from entity without category', () {
        final result = IncomeModel.fromEntity(tIncomeEntity);
        expect(result.id, tIncomeModel.id);
        expect(result.categoryId, null);
      });
    });

    group('toEntity', () {
      test('should return a valid entity (with null category)', () {
        final result = tIncomeModel.toEntity();
        expect(result, tIncomeEntity);
      });
    });

    group('fromJson', () {
      test('should return a valid model from JSON', () {
        final Map<String, dynamic> jsonMap = {
          'id': '1',
          'title': 'Salary',
          'amount': 5000.0,
          'date': tDate.toIso8601String(),
          'categoryId': 'cat1',
          'accountId': 'acc1',
          'categorizationStatusValue': 'categorized',
          'confidenceScoreValue': 1.0,
          'isRecurring': true,
          'notes': 'Notes',
        };
        final result = IncomeModel.fromJson(jsonMap);
        expect(result.id, tIncomeModel.id);
        expect(result.amount, tIncomeModel.amount);
        expect(result.categoryId, tIncomeModel.categoryId);
        expect(result.categorizationStatusValue,
            tIncomeModel.categorizationStatusValue);
        expect(result.confidenceScoreValue, tIncomeModel.confidenceScoreValue);
        expect(result.isRecurring, tIncomeModel.isRecurring);
        expect(result.notes, tIncomeModel.notes);
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () {
        final result = tIncomeModel.toJson();
        final expectedMap = {
          'id': '1',
          'title': 'Salary',
          'amount': 5000.0,
          'date': tDate.toIso8601String(),
          'categoryId': 'cat1',
          'accountId': 'acc1',
          'categorizationStatusValue': 'categorized',
          'confidenceScoreValue': 1.0,
          'isRecurring': true,
          'notes': 'Notes',
        };
        expect(result, expectedMap);
      });
    });
  });
}
