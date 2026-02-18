import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<ExpenseModel> {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

void main() {
  late HiveExpenseLocalDataSource dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeExpenseModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveExpenseLocalDataSource(mockBox);
  });

  final tExpenseModel = ExpenseModel(
    id: '1',
    title: 'Test Expense',
    amount: 100.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    categoryId: 'cat1',
  );

  group('addExpense', () {
    test('should add expense to Hive box', () async {
      // Arrange
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.addExpense(tExpenseModel);

      // Assert
      verify(() => mockBox.put(tExpenseModel.id, tExpenseModel)).called(1);
    });

    test('should throw CacheFailure when adding fails', () async {
      // Arrange
      when(() => mockBox.put(any(), any())).thenThrow(Exception('Hive Error'));

      // Act & Assert
      expect(
        () => dataSource.addExpense(tExpenseModel),
        throwsA(isA<CacheFailure>()),
      );
    });
  });

  group('deleteExpense', () {
    test('should delete expense from Hive box', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.deleteExpense('1');

      // Assert
      verify(() => mockBox.delete('1')).called(1);
    });

    test('should throw CacheFailure when deletion fails', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenThrow(Exception('Hive Error'));

      // Act & Assert
      expect(() => dataSource.deleteExpense('1'), throwsA(isA<CacheFailure>()));
    });
  });

  group('getExpenseById', () {
    test('should return expense when found', () async {
      // Arrange
      when(() => mockBox.get(any())).thenReturn(tExpenseModel);

      // Act
      final result = await dataSource.getExpenseById('1');

      // Assert
      expect(result, tExpenseModel);
      verify(() => mockBox.get('1')).called(1);
    });

    test('should return null when not found', () async {
      // Arrange
      when(() => mockBox.get(any())).thenReturn(null);

      // Act
      final result = await dataSource.getExpenseById('1');

      // Assert
      expect(result, null);
    });

    test('should throw CacheFailure when retrieval fails', () async {
      // Arrange
      when(() => mockBox.get(any())).thenThrow(Exception('Hive Error'));

      // Act & Assert
      expect(
        () => dataSource.getExpenseById('1'),
        throwsA(isA<CacheFailure>()),
      );
    });
  });

  group('updateExpense', () {
    test('should update expense if it exists', () async {
      // Arrange
      when(() => mockBox.containsKey(any())).thenReturn(true);
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.updateExpense(tExpenseModel);

      // Assert
      verify(() => mockBox.put(tExpenseModel.id, tExpenseModel)).called(1);
    });

    test('should throw CacheFailure if expense does not exist', () async {
      // Arrange
      when(() => mockBox.containsKey(any())).thenReturn(false);

      // Act & Assert
      expect(
        () => dataSource.updateExpense(tExpenseModel),
        throwsA(isA<CacheFailure>()),
      );
      verify(() => mockBox.containsKey(tExpenseModel.id)).called(1);
      verifyNever(() => mockBox.put(any(), any()));
    });
  });

  group('clearAll', () {
    test('should clear Hive box', () async {
      // Arrange
      when(() => mockBox.clear()).thenAnswer((_) async => 0);

      // Act
      await dataSource.clearAll();

      // Assert
      verify(() => mockBox.clear()).called(1);
    });
  });
}
