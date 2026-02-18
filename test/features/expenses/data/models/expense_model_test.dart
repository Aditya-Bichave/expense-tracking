import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tDate = DateTime(2024, 1, 1);
  final tExpenseModel = ExpenseModel(
    id: '1',
    title: 'Test Expense',
    amount: 100.0,
    date: tDate,
    accountId: 'acc1',
    categoryId: 'cat1',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 0.9,
    merchantId: 'merch1',
    isRecurring: true,
  );

  final tExpenseEntity = Expense(
    id: '1',
    title: 'Test Expense',
    amount: 100.0,
    date: tDate,
    accountId: 'acc1',
    category: const Category(
      id: 'cat1',
      name: 'Test Category',
      iconName: 'test_icon',
      colorHex: '#000000',
      type: CategoryType.expense,
      isCustom: false,
    ),
    status: CategorizationStatus.categorized,
    confidenceScore: 0.9,
    merchantId: 'merch1',
    isRecurring: true,
  );

  test('should return a valid model from JSON', () {
    // Arrange
    final jsonMap = {
      'id': '1',
      'title': 'Test Expense',
      'amount': 100.0,
      'date': '2024-01-01T00:00:00.000',
      'accountId': 'acc1',
      'categoryId': 'cat1',
      'categorizationStatusValue': 'categorized',
      'confidenceScoreValue': 0.9,
      'merchantId': 'merch1',
      'isRecurring': true,
    };

    // Act
    final result = ExpenseModel.fromJson(jsonMap);

    // Assert
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
    expect(result.merchantId, tExpenseModel.merchantId);
    expect(result.isRecurring, tExpenseModel.isRecurring);
  });

  test('should return a JSON map containing proper data', () {
    // Act
    final result = tExpenseModel.toJson();

    // Assert
    final expectedMap = {
      'id': '1',
      'title': 'Test Expense',
      'amount': 100.0,
      'date': '2024-01-01T00:00:00.000',
      'accountId': 'acc1',
      'categoryId': 'cat1',
      'categorizationStatusValue': 'categorized',
      'confidenceScoreValue': 0.9,
      'merchantId': 'merch1',
      'isRecurring': true,
    };
    expect(result, expectedMap);
  });

  test('should convert from Entity to Model correctly', () {
    // Act
    final result = ExpenseModel.fromEntity(tExpenseEntity);

    // Assert
    expect(result.id, tExpenseEntity.id);
    expect(result.title, tExpenseEntity.title);
    expect(result.amount, tExpenseEntity.amount);
    expect(result.date, tExpenseEntity.date);
    expect(result.accountId, tExpenseEntity.accountId);
    expect(result.categoryId, tExpenseEntity.category?.id);
    expect(result.categorizationStatusValue, 'categorized'); // Enum value check
    expect(result.confidenceScoreValue, tExpenseEntity.confidenceScore);
    expect(result.merchantId, tExpenseEntity.merchantId);
    expect(result.isRecurring, tExpenseEntity.isRecurring);
  });

  test('should convert from Model to Entity correctly (category is null)', () {
    // Act
    final result = tExpenseModel.toEntity();

    // Assert
    expect(result.id, tExpenseModel.id);
    expect(result.title, tExpenseModel.title);
    expect(result.amount, tExpenseModel.amount);
    expect(result.date, tExpenseModel.date);
    expect(result.accountId, tExpenseModel.accountId);
    expect(result.category, isNull); // Category is not hydrated in toEntity
    expect(result.status, CategorizationStatus.categorized);
    expect(result.confidenceScore, tExpenseModel.confidenceScoreValue);
    expect(result.merchantId, tExpenseModel.merchantId);
    expect(result.isRecurring, tExpenseModel.isRecurring);
  });
}
