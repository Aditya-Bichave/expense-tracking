import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source_proxy.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHiveExpenseLocalDataSource extends Mock
    implements HiveExpenseLocalDataSource {}

class MockDemoModeService extends Mock implements DemoModeService {}

class _FakeExpenseModel extends Fake implements ExpenseModel {}

/// The proxy routes every call to either Hive or the in-memory demo service.
/// Getting that wrong writes demo data into the user's real box, or hides real
/// data behind the demo cache — so each method is checked on both branches.
void main() {
  late MockHiveExpenseLocalDataSource hive;
  late MockDemoModeService demo;
  late DemoAwareExpenseDataSource dataSource;

  ExpenseModel expense({
    String id = 'e1',
    String title = 'Groceries',
    double amount = 1000,
    DateTime? date,
    String accountId = 'a1',
    String? categoryId,
  }) => ExpenseModel(
    id: id,
    title: title,
    amount: amount,
    date: date ?? DateTime(2024, 3, 15),
    accountId: accountId,
    categoryId: categoryId,
  );

  setUpAll(() {
    registerFallbackValue(_FakeExpenseModel());
  });

  setUp(() {
    hive = MockHiveExpenseLocalDataSource();
    demo = MockDemoModeService();
    dataSource = DemoAwareExpenseDataSource(
      hiveDataSource: hive,
      demoModeService: demo,
    );
  });

  group('when demo mode is off', () {
    setUp(() => when(() => demo.isDemoActive).thenReturn(false));

    test('add goes to Hive', () async {
      final model = expense();
      when(() => hive.addExpense(any())).thenAnswer((_) async => model);

      expect(await dataSource.addExpense(model), model);
      verify(() => hive.addExpense(model)).called(1);
      verifyNever(() => demo.addDemoExpense(any()));
    });

    test('update goes to Hive', () async {
      final model = expense();
      when(() => hive.updateExpense(any())).thenAnswer((_) async => model);

      expect(await dataSource.updateExpense(model), model);
      verify(() => hive.updateExpense(model)).called(1);
    });

    test('delete goes to Hive', () async {
      when(() => hive.deleteExpense('e1')).thenAnswer((_) async {});

      await dataSource.deleteExpense('e1');

      verify(() => hive.deleteExpense('e1')).called(1);
      verifyNever(() => demo.deleteDemoExpense(any()));
    });

    test('lookup by id goes to Hive', () async {
      when(() => hive.getExpenseById('e1')).thenAnswer((_) async => expense());

      expect((await dataSource.getExpenseById('e1'))?.id, 'e1');
    });

    test('filters are forwarded verbatim to Hive', () async {
      when(
        () => hive.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => []);
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);

      await dataSource.getExpenses(
        startDate: start,
        endDate: end,
        categoryId: 'c1',
        accountId: 'a1',
      );

      verify(
        () => hive.getExpenses(
          startDate: start,
          endDate: end,
          categoryId: 'c1',
          accountId: 'a1',
        ),
      ).called(1);
    });

    test('clearAll reaches Hive', () async {
      when(() => hive.clearAll()).thenAnswer((_) async {});

      await dataSource.clearAll();

      verify(() => hive.clearAll()).called(1);
    });
  });

  group('when demo mode is on', () {
    setUp(() => when(() => demo.isDemoActive).thenReturn(true));

    test('add goes to the demo service, never Hive', () async {
      final model = expense();
      when(() => demo.addDemoExpense(any())).thenAnswer((_) async => model);

      expect(await dataSource.addExpense(model), model);
      verify(() => demo.addDemoExpense(model)).called(1);
      verifyNever(() => hive.addExpense(any()));
    });

    test('update goes to the demo service', () async {
      final model = expense();
      when(() => demo.updateDemoExpense(any())).thenAnswer((_) async => model);

      expect(await dataSource.updateExpense(model), model);
      verifyNever(() => hive.updateExpense(any()));
    });

    test('delete goes to the demo service', () async {
      when(() => demo.deleteDemoExpense('e1')).thenAnswer((_) async {});

      await dataSource.deleteExpense('e1');

      verify(() => demo.deleteDemoExpense('e1')).called(1);
      verifyNever(() => hive.deleteExpense(any()));
    });

    test('lookup by id goes to the demo service', () async {
      when(
        () => demo.getDemoExpenseById('e1'),
      ).thenAnswer((_) async => expense());

      expect((await dataSource.getExpenseById('e1'))?.id, 'e1');
      verifyNever(() => hive.getExpenseById(any()));
    });

    test('clearAll is ignored so the demo dataset survives', () async {
      await dataSource.clearAll();

      verifyNever(() => hive.clearAll());
    });
  });

  group('demo-mode filtering', () {
    setUp(() {
      when(() => demo.isDemoActive).thenReturn(true);
      when(() => demo.getDemoExpenses()).thenAnswer(
        (_) async => [
          expense(
            id: 'jan-a1',
            date: DateTime(2024, 1, 10),
            accountId: 'a1',
            categoryId: 'c1',
          ),
          expense(
            id: 'feb-a2',
            date: DateTime(2024, 2, 10),
            accountId: 'a2',
            categoryId: 'c2',
          ),
          expense(
            id: 'mar-a1',
            date: DateTime(2024, 3, 10),
            accountId: 'a1',
            categoryId: 'c2',
          ),
        ],
      );
    });

    Future<List<String>> idsFor({
      DateTime? startDate,
      DateTime? endDate,
      String? categoryId,
      String? accountId,
    }) async {
      final result = await dataSource.getExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        accountId: accountId,
      );
      return result.map((e) => e.id).toList();
    }

    test('no filters returns everything', () async {
      expect(await idsFor(), ['jan-a1', 'feb-a2', 'mar-a1']);
    });

    test('a start date excludes earlier entries', () async {
      expect(await idsFor(startDate: DateTime(2024, 2, 1)), [
        'feb-a2',
        'mar-a1',
      ]);
    });

    test('an end date is inclusive of the whole day', () async {
      // The boundary matters: an expense recorded at any time on the end date
      // must still be included.
      expect(await idsFor(endDate: DateTime(2024, 2, 10)), [
        'jan-a1',
        'feb-a2',
      ]);
    });

    test('a start date is inclusive of the whole day', () async {
      expect(await idsFor(startDate: DateTime(2024, 3, 10)), ['mar-a1']);
    });

    test('a single account id filters to that account', () async {
      expect(await idsFor(accountId: 'a1'), ['jan-a1', 'mar-a1']);
    });

    test('a comma-separated account list matches any of them', () async {
      expect(await idsFor(accountId: 'a1,a2'), ['jan-a1', 'feb-a2', 'mar-a1']);
    });

    test('a comma-separated category list matches any of them', () async {
      expect(await idsFor(categoryId: 'c2'), ['feb-a2', 'mar-a1']);
    });

    test('an empty filter string is treated as no filter', () async {
      expect(await idsFor(accountId: '', categoryId: ''), [
        'jan-a1',
        'feb-a2',
        'mar-a1',
      ]);
    });

    test('filters combine as an intersection', () async {
      expect(
        await idsFor(
          startDate: DateTime(2024, 2, 1),
          accountId: 'a1',
          categoryId: 'c2',
        ),
        ['mar-a1'],
      );
    });

    test('a filter matching nothing returns empty', () async {
      expect(await idsFor(accountId: 'nope'), isEmpty);
    });
  });
}
