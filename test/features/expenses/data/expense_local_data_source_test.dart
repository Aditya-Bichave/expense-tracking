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
    Hive.registerAdapter(ExpenseModelAdapter());
    box = await Hive.openBox<ExpenseModel>('expenses_test');
    dataSource = HiveExpenseLocalDataSource(box);

    final e1 = ExpenseModel(
      id: '1',
      title: 'A',
      amount: 10,
      date: DateTime(2023, 1, 1),
      accountId: 'acc1',
      categoryId: 'cat1',
    );
    final e2 = ExpenseModel(
      id: '2',
      title: 'B',
      amount: 20,
      date: DateTime(2023, 1, 15),
      accountId: 'acc2',
      categoryId: 'cat2',
    );
    final e3 = ExpenseModel(
      id: '3',
      title: 'C',
      amount: 30,
      date: DateTime(2023, 2, 5),
      accountId: 'acc1',
      categoryId: 'cat1',
    );
    await box.putAll({'1': e1, '2': e2, '3': e3});
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('expenses_test');
    await tempDir.delete(recursive: true);
  });

  test('applies filters in HiveExpenseLocalDataSource', () async {
    final results = await dataSource.getExpenses(
      startDate: DateTime(2023, 1, 10),
      endDate: DateTime(2023, 1, 31),
      accountId: 'acc2',
      categoryId: 'cat2',
    );
    expect(results.length, 1);
    expect(results.first.id, '2');
  });
}
