import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:hive_ce/hive.dart';

class MockBox<T> extends Mock implements Box<T> {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

void main() {
  late MockBox<ExpenseModel> mockBox;
  late HiveExpenseLocalDataSource dataSource;

  setUpAll(() {
    registerFallbackValue(FakeExpenseModel());
  });

  setUp(() {
    mockBox = MockBox<ExpenseModel>();
    dataSource = HiveExpenseLocalDataSource(mockBox);
  });

  group('HiveExpenseLocalDataSource', () {
    final tModel1 = ExpenseModel(
      id: '1',
      title: 'Expense 1',
      amount: 100.0,
      categoryId: 'cat1',
      date: DateTime(2023, 1, 1),
      notes: 'note1',
      accountId: 'acc1',
    );
    final tModel2 = ExpenseModel(
      id: '2',
      title: 'Expense 2',
      amount: 200.0,
      categoryId: 'cat2',
      date: DateTime(2023, 1, 2),
      notes: 'note2',
      accountId: 'acc2',
    );
    final tModels = [tModel1, tModel2];

    test('addExpense puts single expense into box', () async {
      when(
        () => mockBox.put(any<dynamic>(), any<ExpenseModel>()),
      ).thenAnswer((_) async => Future.value());

      final result = await dataSource.addExpense(tModel1);

      expect(result, equals(tModel1));
      verify(() => mockBox.put(tModel1.id, tModel1)).called(1);
    });

    test('addExpense throws CacheFailure on exception', () async {
      when(
        () => mockBox.put(any<dynamic>(), any<ExpenseModel>()),
      ).thenThrow(Exception('error'));

      expect(
        () => dataSource.addExpense(tModel1),
        throwsA(isA<CacheFailure>()),
      );
    });

    test('deleteExpense deletes from box', () async {
      when(
        () => mockBox.delete(any<dynamic>()),
      ).thenAnswer((_) async => Future.value());

      await dataSource.deleteExpense('1');

      verify(() => mockBox.delete('1')).called(1);
    });

    test('getExpenses returns values filtered by date', () async {
      when(() => mockBox.values).thenReturn(tModels);

      final result = await dataSource.getExpenses(
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 1, 23, 59, 59),
      );

      expect(result, equals([tModel1]));
    });

    test('getExpenses returns values filtered by categoryId', () async {
      when(() => mockBox.values).thenReturn(tModels);

      final result = await dataSource.getExpenses(categoryId: 'cat1');

      expect(result, equals([tModel1]));
    });

    test('getExpenses returns values filtered by accountId', () async {
      when(() => mockBox.values).thenReturn(tModels);

      final result = await dataSource.getExpenses(accountId: 'acc2');

      expect(result, equals([tModel2]));
    });

    test('getExpenseById returns expense if exists', () async {
      when(() => mockBox.get(any<dynamic>())).thenReturn(tModel1);

      final result = await dataSource.getExpenseById('1');

      expect(result, equals(tModel1));
      verify(() => mockBox.get('1')).called(1);
    });

    test('getExpenseById returns null if not exists', () async {
      when(() => mockBox.get(any<dynamic>())).thenReturn(null);

      final result = await dataSource.getExpenseById('unknown');

      expect(result, isNull);
      verify(() => mockBox.get('unknown')).called(1);
    });

    test('updateExpense updates expense if exists', () async {
      when(() => mockBox.containsKey(any<dynamic>())).thenReturn(true);
      when(
        () => mockBox.put(any<dynamic>(), any<ExpenseModel>()),
      ).thenAnswer((_) async => Future.value());

      final result = await dataSource.updateExpense(tModel1);

      expect(result, equals(tModel1));
      verify(() => mockBox.containsKey(tModel1.id)).called(1);
      verify(() => mockBox.put(tModel1.id, tModel1)).called(1);
    });

    test('updateExpense throws CacheFailure if not exists', () async {
      when(() => mockBox.containsKey(any<dynamic>())).thenReturn(false);

      expect(
        () => dataSource.updateExpense(tModel1),
        throwsA(isA<CacheFailure>()),
      );
    });

    test('clearAll clears the box', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 2);

      await dataSource.clearAll();

      verify(() => mockBox.clear()).called(1);
    });
  });
}
