import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';

void main() {
  late Directory tempDir;
  late Box<IncomeModel> box;
  late IncomeLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    Hive.registerAdapter(IncomeModelAdapter());
    box = await Hive.openBox<IncomeModel>('incomes_test');
    dataSource = HiveIncomeLocalDataSource(box);

    final i1 = IncomeModel(
      id: '1',
      title: 'A',
      amount: 10,
      date: DateTime(2023, 1, 1),
      accountId: 'acc1',
      categoryId: 'cat1',
    );
    final i2 = IncomeModel(
      id: '2',
      title: 'B',
      amount: 20,
      date: DateTime(2023, 1, 20),
      accountId: 'acc2',
      categoryId: 'cat2',
    );
    await box.putAll({'1': i1, '2': i2});
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('incomes_test');
    await tempDir.delete(recursive: true);
  });

  test('applies filters in HiveIncomeLocalDataSource', () async {
    final results = await dataSource.getIncomes(
      startDate: DateTime(2023, 1, 10),
      endDate: DateTime(2023, 1, 31),
      accountId: 'acc2',
      categoryId: 'cat2',
    );
    expect(results.length, 1);
    expect(results.first.id, '2');
  });
}
