import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<GroupExpenseModel> {}

class FakeGroupExpenseModel extends Fake implements GroupExpenseModel {}

void main() {
  late GroupExpensesLocalDataSourceImpl dataSource;
  late MockBox mockBox;

  setUpAll(() {
    registerFallbackValue(FakeGroupExpenseModel());
  });

  setUp(() {
    mockBox = MockBox();
    dataSource = GroupExpensesLocalDataSourceImpl(mockBox);
  });

  final tExpense = GroupExpenseModel(
    id: '1',
    groupId: 'g1',
    createdBy: 'c1',
    title: 'Dinner',
    amount: 100,
    currency: 'USD',
    occurredAt: DateTime(2023, 10, 27),
    createdAt: DateTime(2023, 10, 27),
    updatedAt: DateTime(2023, 10, 27),
  );

  group('saveExpense', () {
    test('should call box.put', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await dataSource.saveExpense(tExpense);
      verify(() => mockBox.put('1', tExpense)).called(1);
    });
  });

  group('saveExpenses', () {
    test('should call box.putAll', () async {
      when(() => mockBox.putAll(any())).thenAnswer((_) async {});
      await dataSource.saveExpenses([tExpense]);
      verify(() => mockBox.putAll({'1': tExpense})).called(1);
    });
  });

  group('getExpenses', () {
    test('should return expenses for the given groupId', () {
      final tExpense2 = GroupExpenseModel(
        id: '2',
        groupId: 'g2',
        createdBy: 'c1',
        title: 'Lunch',
        amount: 50,
        currency: 'USD',
        occurredAt: DateTime(2023, 10, 27),
        createdAt: DateTime(2023, 10, 27),
        updatedAt: DateTime(2023, 10, 27),
      );

      when(() => mockBox.values).thenReturn([tExpense, tExpense2]);

      final result = dataSource.getExpenses('g1');

      expect(result, [tExpense]);
    });
  });
}
