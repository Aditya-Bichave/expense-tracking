import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source_proxy.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';

class MockHiveIncomeLocalDataSource extends Mock
    implements HiveIncomeLocalDataSource {}

class MockDemoModeService extends Mock implements DemoModeService {}

void main() {
  late DemoAwareIncomeDataSource dataSource;
  late MockHiveIncomeLocalDataSource mockHiveDataSource;
  late MockDemoModeService mockDemoModeService;

  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Test',
    amount: 100,
    date: DateTime(2023),
    accountId: 'a1',
    isRecurring: false,
  );

  setUpAll(() {
    registerFallbackValue(tIncomeModel);
  });

  setUp(() {
    mockHiveDataSource = MockHiveIncomeLocalDataSource();
    mockDemoModeService = MockDemoModeService();
    dataSource = DemoAwareIncomeDataSource(
      hiveDataSource: mockHiveDataSource,
      demoModeService: mockDemoModeService,
    );
  });

  group('addIncome', () {
    test('should forward to Hive when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.addIncome(any()),
      ).thenAnswer((_) async => tIncomeModel);

      await dataSource.addIncome(tIncomeModel);

      verify(() => mockHiveDataSource.addIncome(any()));
    });
  });
}
