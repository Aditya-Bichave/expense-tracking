import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<BudgetModel> {}

class FakeBudgetModel extends Fake implements BudgetModel {}

void main() {
  late HiveBudgetLocalDataSource dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeBudgetModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveBudgetLocalDataSource(mockBox);
  });

  final tBudgetModel = BudgetModel(
    id: '1',
    name: 'Monthly Budget',
    targetAmount: 500.0,
    periodTypeIndex: 0, // monthly
    startDate: DateTime(2024, 1, 1),
    categoryIds: ['cat1'],
    budgetTypeIndex: 1, // categorySpecific
    createdAt: DateTime.now(),
  );

  group('getBudgets', () {
    test('should return list of BudgetModel from Hive', () async {
      // Arrange
      when(() => mockBox.values).thenReturn([tBudgetModel]);

      // Act
      final result = await dataSource.getBudgets();

      // Assert
      expect(result, [tBudgetModel]);
    });

    test('should throw CacheFailure when Hive access fails', () async {
      // Arrange
      when(() => mockBox.values).thenThrow(Exception());

      // Act & Assert
      expect(() => dataSource.getBudgets(), throwsA(isA<CacheFailure>()));
    });
  });

  group('saveBudget', () {
    test('should add/update budget to Hive', () async {
      // Arrange
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.saveBudget(tBudgetModel);

      // Assert
      verify(() => mockBox.put(tBudgetModel.id, tBudgetModel)).called(1);
    });

    test('should throw CacheFailure when saving fails', () async {
      // Arrange
      when(() => mockBox.put(any(), any())).thenThrow(Exception());

      // Act & Assert
      expect(
        () => dataSource.saveBudget(tBudgetModel),
        throwsA(isA<CacheFailure>()),
      );
    });
  });

  group('deleteBudget', () {
    test('should delete budget from Hive', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.deleteBudget('1');

      // Assert
      verify(() => mockBox.delete('1')).called(1);
    });

    test('should throw CacheFailure when deletion fails', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenThrow(Exception());

      // Act & Assert
      expect(() => dataSource.deleteBudget('1'), throwsA(isA<CacheFailure>()));
    });
  });
}
