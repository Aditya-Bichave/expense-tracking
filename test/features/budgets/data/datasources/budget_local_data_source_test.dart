import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/core/error/failure.dart';

class MockBox extends Mock implements Box<BudgetModel> {}

class FakeBudgetModel extends Fake implements BudgetModel {}

void main() {
  late HiveBudgetLocalDataSource dataSource;
  late MockBox mockBox;

  final tBudget = BudgetModel(
    id: '1',
    name: 'Test Budget',
    budgetTypeIndex: 0,
    targetAmount: 500,
    periodTypeIndex: 0,
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(FakeBudgetModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveBudgetLocalDataSource(mockBox);
  });

  group('HiveBudgetLocalDataSource', () {
    group('saveBudget', () {
      test('should save budget to box', () async {
        when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

        await dataSource.saveBudget(tBudget);

        verify(() => mockBox.put(tBudget.id, tBudget)).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(
          () => mockBox.put(any(), any()),
        ).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.saveBudget(tBudget),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('getBudgets', () {
      test('should return list of budgets from box', () async {
        final List<BudgetModel> tList = [tBudget];
        when(() => mockBox.values).thenReturn(tList);

        final result = await dataSource.getBudgets();

        expect(result, equals(tList));
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.values).thenThrow(Exception('Hive Error'));

        expect(() => dataSource.getBudgets(), throwsA(isA<CacheFailure>()));
      });
    });

    group('getBudgetById', () {
      test('should return budget if found', () async {
        when(() => mockBox.get(any())).thenReturn(tBudget);

        final result = await dataSource.getBudgetById(tBudget.id);

        expect(result, equals(tBudget));
        verify(() => mockBox.get(tBudget.id)).called(1);
      });

      test('should return null if not found', () async {
        when(() => mockBox.get(any())).thenReturn(null);

        final result = await dataSource.getBudgetById('non-existent');

        expect(result, isNull);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.get(any())).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.getBudgetById(tBudget.id),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('deleteBudget', () {
      test('should delete budget from box', () async {
        when(() => mockBox.delete(any())).thenAnswer((_) async => {});

        await dataSource.deleteBudget(tBudget.id);

        verify(() => mockBox.delete(tBudget.id)).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.delete(any())).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.deleteBudget(tBudget.id),
          throwsA(isA<CacheFailure>()),
        );
      });
    });

    group('clearAllBudgets', () {
      test('should clear box', () async {
        when(() => mockBox.clear()).thenAnswer((_) async => 0);

        await dataSource.clearAllBudgets();

        verify(() => mockBox.clear()).called(1);
      });

      test('should throw CacheFailure on error', () async {
        when(() => mockBox.clear()).thenThrow(Exception('Hive Error'));

        expect(
          () => dataSource.clearAllBudgets(),
          throwsA(isA<CacheFailure>()),
        );
      });
    });
  });
}
