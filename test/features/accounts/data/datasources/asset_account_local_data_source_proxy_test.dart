import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source_proxy.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHiveAssetAccountLocalDataSource extends Mock
    implements HiveAssetAccountLocalDataSource {}

class MockDemoModeService extends Mock implements DemoModeService {}

// Update Fake to implement 'name'
class FakeAssetAccountModel extends Fake implements AssetAccountModel {
  @override
  String get name => 'Fake Account';
}

void main() {
  late DemoAwareAccountDataSource dataSource;
  late MockHiveAssetAccountLocalDataSource mockHiveDataSource;
  late MockDemoModeService mockDemoModeService;

  setUpAll(() {
    registerFallbackValue(FakeAssetAccountModel());
  });

  setUp(() {
    mockHiveDataSource = MockHiveAssetAccountLocalDataSource();
    mockDemoModeService = MockDemoModeService();
    dataSource = DemoAwareAccountDataSource(
      hiveDataSource: mockHiveDataSource,
      demoModeService: mockDemoModeService,
    );
  });

  group('getAssetAccounts', () {
    test('calls hiveDataSource when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.getAssetAccounts(),
      ).thenAnswer((_) async => []);

      await dataSource.getAssetAccounts();

      verify(() => mockHiveDataSource.getAssetAccounts()).called(1);
      verifyNever(() => mockDemoModeService.getDemoAccounts());
    });

    test('calls demoModeService when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.getDemoAccounts(),
      ).thenAnswer((_) async => []);

      await dataSource.getAssetAccounts();

      verify(() => mockDemoModeService.getDemoAccounts()).called(1);
      verifyNever(() => mockHiveDataSource.getAssetAccounts());
    });
  });

  group('addAssetAccount', () {
    final account = FakeAssetAccountModel();

    test('calls hiveDataSource when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.addAssetAccount(any()),
      ).thenAnswer((_) async => account);

      await dataSource.addAssetAccount(account);

      verify(() => mockHiveDataSource.addAssetAccount(account)).called(1);
      verifyNever(() => mockDemoModeService.addDemoAccount(any()));
    });

    test('calls demoModeService when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.addDemoAccount(any()),
      ).thenAnswer((_) async => account);

      await dataSource.addAssetAccount(account);

      verify(() => mockDemoModeService.addDemoAccount(account)).called(1);
      verifyNever(() => mockHiveDataSource.addAssetAccount(any()));
    });
  });

  group('updateAssetAccount', () {
    final account = FakeAssetAccountModel();

    test('calls hiveDataSource when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.updateAssetAccount(any()),
      ).thenAnswer((_) async => account);

      await dataSource.updateAssetAccount(account);

      verify(() => mockHiveDataSource.updateAssetAccount(account)).called(1);
      verifyNever(() => mockDemoModeService.updateDemoAccount(any()));
    });

    test('calls demoModeService when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.updateDemoAccount(any()),
      ).thenAnswer((_) async => account);

      await dataSource.updateAssetAccount(account);

      verify(() => mockDemoModeService.updateDemoAccount(account)).called(1);
      verifyNever(() => mockHiveDataSource.updateAssetAccount(any()));
    });
  });

  group('deleteAssetAccount', () {
    const id = 'test_id';

    test('calls hiveDataSource when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(
        () => mockHiveDataSource.deleteAssetAccount(any()),
      ).thenAnswer((_) async {});

      await dataSource.deleteAssetAccount(id);

      verify(() => mockHiveDataSource.deleteAssetAccount(id)).called(1);
      verifyNever(() => mockDemoModeService.deleteDemoAccount(any()));
    });

    test('calls demoModeService when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);
      when(
        () => mockDemoModeService.deleteDemoAccount(any()),
      ).thenAnswer((_) async {});

      await dataSource.deleteAssetAccount(id);

      verify(() => mockDemoModeService.deleteDemoAccount(id)).called(1);
      verifyNever(() => mockHiveDataSource.deleteAssetAccount(any()));
    });
  });

  group('clearAll', () {
    test('calls hiveDataSource when demo mode is inactive', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(false);
      when(() => mockHiveDataSource.clearAll()).thenAnswer((_) async {});

      await dataSource.clearAll();

      verify(() => mockHiveDataSource.clearAll()).called(1);
    });

    test('does nothing when demo mode is active', () async {
      when(() => mockDemoModeService.isDemoActive).thenReturn(true);

      await dataSource.clearAll();

      verifyNever(() => mockHiveDataSource.clearAll());
    });
  });
}
