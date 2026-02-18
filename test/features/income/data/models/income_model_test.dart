import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tDate = DateTime(2024, 1, 1);
  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Test Income',
    amount: 5000.0,
    date: tDate,
    accountId: 'acc1',
    categoryId: 'cat1',
    notes: 'Bonus',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 0.9,
    merchantId: 'merch1',
    isRecurring: true,
  );

  final tIncomeEntity = Income(
    id: '1',
    title: 'Test Income',
    amount: 5000.0,
    date: tDate,
    accountId: 'acc1',
    category: const Category(
      id: 'cat1',
      name: 'Test Category',
      iconName: 'test_icon',
      colorHex: '#000000',
      type: CategoryType.income,
      isCustom: false,
    ),
    notes: 'Bonus',
    status: CategorizationStatus.categorized,
    confidenceScore: 0.9,
    merchantId: 'merch1',
    isRecurring: true,
  );

  test('should return a valid model from JSON', () {
    // Arrange
    final jsonMap = {
      'id': '1',
      'title': 'Test Income',
      'amount': 5000.0,
      'date': '2024-01-01T00:00:00.000',
      'accountId': 'acc1',
      'categoryId': 'cat1',
      'notes': 'Bonus',
      'categorizationStatusValue': 'categorized',
      'confidenceScoreValue': 0.9,
      'merchantId': 'merch1',
      'isRecurring': true,
    };

    // Act
    final result = IncomeModel.fromJson(jsonMap);

    // Assert
    expect(result.id, tIncomeModel.id);
    expect(result.title, tIncomeModel.title);
    expect(result.amount, tIncomeModel.amount);
    expect(result.date, tIncomeModel.date);
    expect(result.accountId, tIncomeModel.accountId);
    expect(result.categoryId, tIncomeModel.categoryId);
    expect(result.notes, tIncomeModel.notes);
    expect(
      result.categorizationStatusValue,
      tIncomeModel.categorizationStatusValue,
    );
    expect(result.confidenceScoreValue, tIncomeModel.confidenceScoreValue);
    expect(result.merchantId, tIncomeModel.merchantId);
    expect(result.isRecurring, tIncomeModel.isRecurring);
  });

  test('should return a JSON map containing proper data', () {
    // Act
    final result = tIncomeModel.toJson();

    // Assert
    final expectedMap = {
      'id': '1',
      'title': 'Test Income',
      'amount': 5000.0,
      'date': '2024-01-01T00:00:00.000',
      'accountId': 'acc1',
      'categoryId': 'cat1',
      'notes': 'Bonus',
      'categorizationStatusValue': 'categorized',
      'confidenceScoreValue': 0.9,
      'merchantId': 'merch1',
      'isRecurring': true,
    };
    expect(result, expectedMap);
  });

  test('should convert from Entity to Model correctly', () {
    // Act
    final result = IncomeModel.fromEntity(tIncomeEntity);

    // Assert
    expect(result.id, tIncomeEntity.id);
    expect(result.title, tIncomeEntity.title);
    expect(result.amount, tIncomeEntity.amount);
    expect(result.date, tIncomeEntity.date);
    expect(result.accountId, tIncomeEntity.accountId);
    expect(result.categoryId, tIncomeEntity.category?.id);
    expect(result.notes, tIncomeEntity.notes);
    expect(result.categorizationStatusValue, 'categorized'); // Enum value check
    expect(result.confidenceScoreValue, tIncomeEntity.confidenceScore);
    expect(result.merchantId, tIncomeEntity.merchantId);
    expect(result.isRecurring, tIncomeEntity.isRecurring);
  });

  test('should convert from Model to Entity correctly (category is null)', () {
    // Act
    final result = tIncomeModel.toEntity();

    // Assert
    expect(result.id, tIncomeModel.id);
    expect(result.title, tIncomeModel.title);
    expect(result.amount, tIncomeModel.amount);
    expect(result.date, tIncomeModel.date);
    expect(result.accountId, tIncomeModel.accountId);
    expect(result.category, isNull); // Category is not hydrated in toEntity
    expect(result.notes, tIncomeModel.notes);
    expect(result.status, CategorizationStatus.categorized);
    expect(result.confidenceScore, tIncomeModel.confidenceScoreValue);
    expect(result.merchantId, tIncomeModel.merchantId);
    expect(result.isRecurring, tIncomeModel.isRecurring);
  });
}
