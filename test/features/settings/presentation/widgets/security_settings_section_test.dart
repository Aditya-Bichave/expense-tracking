import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/security_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/pump_app.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockStorage = MockSecureStorageService();
    final sl = GetIt.instance;
    if (sl.isRegistered<SecureStorageService>()) {
      sl.unregister<SecureStorageService>();
    }
    sl.registerSingleton<SecureStorageService>(mockStorage);
  });

  testWidgets('SecuritySettingsSection renders and loads state', (
    WidgetTester tester,
  ) async {
    when(() => mockStorage.isBiometricEnabled()).thenAnswer((_) async => true);

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const Scaffold(body: SecuritySettingsSection()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsOneWidget);
    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switchTile.value, isTrue);
    verify(() => mockStorage.isBiometricEnabled()).called(1);
  });

  testWidgets('SecuritySettingsSection toggles switch and saves', (
    WidgetTester tester,
  ) async {
    when(() => mockStorage.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => mockStorage.setBiometricEnabled(true)).thenAnswer((_) async {});
    when(() => mockStorage.getPin()).thenAnswer((_) async => '1234');

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const Scaffold(body: SecuritySettingsSection()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    verify(() => mockStorage.setBiometricEnabled(true)).called(1);
  });
}
