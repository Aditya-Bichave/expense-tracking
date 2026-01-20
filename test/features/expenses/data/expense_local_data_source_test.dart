import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';

void main() {
  late Directory tempDir;
  late Box<ExpenseModel> box;
  late ExpenseLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    // Register adapter if not already registered (checking strictly not possible easily, try-catch or just register)
    // In test environment, usually safe to register.
    if (!Hive.isAdapterRegistered(0)) { // Assuming typeId 0 or similar.
       // Actually we can't easily check typeId without knowing it.
       // But in the previous read_file, it was: Hive.registerAdapter(ExpenseModelAdapter());
       // We'll trust that works or wrap in try-catch if needed, but standard Hive test setup does this.
       Hive.registerAdapter(ExpenseModelAdapter());
    }

    box = await Hive.openBox<ExpenseModel>('expenses_test');
    dataSource = HiveExpenseLocalDataSource(box);

    final e1 = ExpenseModel(
      id: '1',
      title: 'A',
      amount: 10,
      date: DateTime(2023, 1, 1, 10, 0), // Jan 1, 10am
      accountId: 'acc1',
      categoryId: 'cat1',
    );
    final e2 = ExpenseModel(
      id: '2',
      title: 'B',
      amount: 20,
      date: DateTime(2023, 1, 15, 14, 0), // Jan 15, 2pm
      accountId: 'acc2',
      categoryId: 'cat2',
    );
    final e3 = ExpenseModel(
      id: '3',
      title: 'C',
      amount: 30,
      date: DateTime(2023, 2, 5, 9, 0), // Feb 5, 9am
      accountId: 'acc1',
      categoryId: 'cat1',
    );
     final e4 = ExpenseModel(
      id: '4',
      title: 'D',
      amount: 40,
      date: DateTime(2023, 1, 15, 23, 59, 59), // Jan 15, End of day
      accountId: 'acc2',
      categoryId: 'cat3',
    );
    final e5 = ExpenseModel(
      id: '5',
      title: 'E',
      amount: 50,
      date: DateTime(2023, 1, 15, 0, 0, 0), // Jan 15, Start of day
      accountId: 'acc3',
      categoryId: 'cat2',
    );

    await box.putAll({'1': e1, '2': e2, '3': e3, '4': e4, '5': e5});
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('expenses_test');
    await tempDir.delete(recursive: true);
  });

  test('applies date range filters correctly (inclusive)', () async {
    // Filter Jan 15 to Jan 15. Should get e2, e4, e5.
    final results = await dataSource.getExpenses(
      startDate: DateTime(2023, 1, 15),
      endDate: DateTime(2023, 1, 15),
    );
    expect(results.length, 3);
    final ids = results.map((e) => e.id).toSet();
    expect(ids, containsAll(['2', '4', '5']));
  });

  test('applies start date filter correctly (inclusive)', () async {
    // Start Jan 15. Should get e2, e4, e5, e3. (e1 is Jan 1).
    final results = await dataSource.getExpenses(
      startDate: DateTime(2023, 1, 15),
    );
    expect(results.length, 4);
    final ids = results.map((e) => e.id).toSet();
    expect(ids, containsAll(['2', '3', '4', '5']));
    expect(ids, isNot(contains('1')));
  });

  test('applies end date filter correctly (inclusive)', () async {
    // End Jan 15. Should get e1, e5, e2, e4. (e3 is Feb 5).
    final results = await dataSource.getExpenses(
      endDate: DateTime(2023, 1, 15),
    );
    expect(results.length, 4);
    final ids = results.map((e) => e.id).toSet();
    expect(ids, containsAll(['1', '2', '4', '5']));
    expect(ids, isNot(contains('3')));
  });

  test('applies single ID filters correctly', () async {
    final results = await dataSource.getExpenses(
      accountId: 'acc2',
      categoryId: 'cat2',
    );
    // acc2 has e2 (cat2), e4 (cat3).
    // cat2 has e2 (acc2), e5 (acc3).
    // Intersection: e2.
    expect(results.length, 1);
    expect(results.first.id, '2');
  });

  test('applies multiple ID filters correctly', () async {
    // accountId = 'acc1,acc2' (e1, e3, e2, e4)
    // categoryId = 'cat1' (e1, e3)
    // Intersection: e1, e3.
    final results = await dataSource.getExpenses(
      accountId: 'acc1,acc2',
      categoryId: 'cat1',
    );
    expect(results.length, 2);
    final ids = results.map((e) => e.id).toSet();
    expect(ids, containsAll(['1', '3']));
  });

   test('applies multiple ID filters correctly (Or logic within type)', () async {
    // accountId = 'acc1'
    // categoryId = 'cat1,cat2'
    // e1: acc1, cat1 -> Match
    // e2: acc2, cat2 -> Fail account
    // e3: acc1, cat1 -> Match
    // e4: acc2, cat3 -> Fail account, fail cat
    // e5: acc3, cat2 -> Fail account

    final results = await dataSource.getExpenses(
      accountId: 'acc1',
      categoryId: 'cat1,cat2',
    );
    expect(results.length, 2);
    final ids = results.map((e) => e.id).toSet();
    expect(ids, containsAll(['1', '3']));
  });
}
