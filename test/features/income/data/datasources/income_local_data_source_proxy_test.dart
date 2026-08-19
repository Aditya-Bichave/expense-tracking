import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source_proxy.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHiveIncomeLocalDataSource extends Mock
    implements HiveIncomeLocalDataSource {}

class MockDemoModeService extends Mock implements DemoModeService {}

class _FakeIncomeModel extends Fake implements IncomeModel {}

/// The proxy routes every call to either Hive or the in-memory demo service.
/// Getting that wrong writes demo data into the user's real box, or hides real
/// data behind the demo cache — so each method is checked on both branches.
void main() {
  late MockHiveIncomeLocalDataSource hive;
  late MockDemoModeService demo;
  late DemoAwareIncomeDataSource dataSource;

  IncomeModel income({
    String id = 'i1',
    String title = 'Salary',
    double amount = 1000,
    DateTime? date,
    String accountId = 'a1',
    String? categoryId,
  }) => IncomeModel(
    id: id,
    title: title,
    amount: amount,
    date: date ?? DateTime(2024, 3, 15),
    accountId: accountId,
    categoryId: categoryId,
  );

  setUpAll(() {
    registerFallbackValue(_FakeIncomeModel());
  });

  setUp(() {
    hive = MockHiveIncomeLocalDataSource();
    demo = MockDemoModeService();
    dataSource = DemoAwareIncomeDataSource(
      hiveDataSource: hive,
      demoModeService: demo,
    );
  });

  group('when demo mode is off', () {
    setUp(() => when(() => demo.isDemoActive).thenReturn(false));

    test('add goes to Hive', () async {
      final model = income();
      when(() => hive.addIncome(any())).thenAnswer((_) async => model);

      expect(await dataSource.addIncome(model), model);
      verify(() => hive.addIncome(model)).called(1);
      verifyNever(() => demo.addDemoIncome(any()));
    });

    test('update goes to Hive', () async {
      final model = income();
      when(() => hive.updateIncome(any())).thenAnswer((_) async => model);

      expect(await dataSource.updateIncome(model), model);
      verify(() => hive.updateIncome(model)).called(1);
    });

    test('delete goes to Hive', () async {
      when(() => hive.deleteIncome('i1')).thenAnswer((_) async {});

      await dataSource.deleteIncome('i1');

      verify(() => hive.deleteIncome('i1')).called(1);
      verifyNever(() => demo.deleteDemoIncome(any()));
    });

    test('lookup by id goes to Hive', () async {
      when(() => hive.getIncomeById('i1')).thenAnswer((_) async => income());

      expect((await dataSource.getIncomeById('i1'))?.id, 'i1');
    });

    test('filters are forwarded verbatim to Hive', () async {
      when(
        () => hive.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => []);
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);

      await dataSource.getIncomes(
        startDate: start,
        endDate: end,
        categoryId: 'c1',
        accountId: 'a1',
      );

      verify(
        () => hive.getIncomes(
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
      final model = income();
      when(() => demo.addDemoIncome(any())).thenAnswer((_) async => model);

      expect(await dataSource.addIncome(model), model);
      verify(() => demo.addDemoIncome(model)).called(1);
      verifyNever(() => hive.addIncome(any()));
    });

    test('update goes to the demo service', () async {
      final model = income();
      when(() => demo.updateDemoIncome(any())).thenAnswer((_) async => model);

      expect(await dataSource.updateIncome(model), model);
      verifyNever(() => hive.updateIncome(any()));
    });

    test('delete goes to the demo service', () async {
      when(() => demo.deleteDemoIncome('i1')).thenAnswer((_) async {});

      await dataSource.deleteIncome('i1');

      verify(() => demo.deleteDemoIncome('i1')).called(1);
      verifyNever(() => hive.deleteIncome(any()));
    });

    test('lookup by id goes to the demo service', () async {
      when(
        () => demo.getDemoIncomeById('i1'),
      ).thenAnswer((_) async => income());

      expect((await dataSource.getIncomeById('i1'))?.id, 'i1');
      verifyNever(() => hive.getIncomeById(any()));
    });

    test('clearAll is ignored so the demo dataset survives', () async {
      await dataSource.clearAll();

      verifyNever(() => hive.clearAll());
    });
  });

  group('demo-mode filtering', () {
    setUp(() {
      when(() => demo.isDemoActive).thenReturn(true);
      when(() => demo.getDemoIncomes()).thenAnswer(
        (_) async => [
          income(
            id: 'jan-a1',
            date: DateTime(2024, 1, 10),
            accountId: 'a1',
            categoryId: 'c1',
          ),
          income(
            id: 'feb-a2',
            date: DateTime(2024, 2, 10),
            accountId: 'a2',
            categoryId: 'c2',
          ),
          income(
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
      final result = await dataSource.getIncomes(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        accountId: accountId,
      );
      return result.map((i) => i.id).toList();
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
      // The boundary matters: an income recorded at any time on the end date
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
