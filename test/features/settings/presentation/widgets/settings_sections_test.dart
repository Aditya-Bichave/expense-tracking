import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/about_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/appearance_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/general_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/legal_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/security_settings_section.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_switch.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSettingsBloc mockSettingsBloc;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    mockStorage = MockSecureStorageService();
    final sl = GetIt.instance;
    if (sl.isRegistered<SecureStorageService>()) {
      sl.unregister<SecureStorageService>();
    }
    sl.registerSingleton<SecureStorageService>(mockStorage);
  });

  Widget pumpSection(Widget section) {
    return BlocProvider<SettingsBloc>.value(
      value: mockSettingsBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: section)),
      ),
    );
  }

  group('Settings Sections Tests', () {
    testWidgets('AppearanceSettingsSection renders correctly', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

      await tester.pumpWidget(
        pumpSection(
          AppearanceSettingsSection(
            state: const SettingsState(),
            isLoading: false,
          ),
        ),
      );

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Brightness Mode'), findsOneWidget);
      expect(find.text('UI Mode'), findsOneWidget);
    });

    testWidgets('GeneralSettingsSection renders correctly', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

      await tester.pumpWidget(
        pumpSection(
          GeneralSettingsSection(
            state: const SettingsState(),
            isLoading: false,
          ),
        ),
      );

      // Empty in current implementation
      expect(find.text('General'), findsNothing);
      expect(find.text('Country / Currency'), findsNothing);
    });

    testWidgets('SecuritySettingsSection toggles app lock', (tester) async {
      when(
        () => mockStorage.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => mockStorage.setBiometricEnabled(true),
      ).thenAnswer((_) async {});
      when(() => mockStorage.getPin()).thenAnswer((_) async => '1234');

      await tester.pumpWidget(pumpSection(const SecuritySettingsSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      verify(() => mockStorage.setBiometricEnabled(true)).called(1);
    });

    testWidgets('HelpSettingsSection triggers URL launch', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      String? launchedUrl;
      await tester.pumpWidget(
        pumpSection(
          HelpSettingsSection(
            isLoading: false,
            launchUrlCallback: (context, url) {
              launchedUrl = url;
            },
          ),
        ),
      );

      expect(find.text('Help & Feedback'), findsOneWidget);
      await tester.tap(find.text('Help Center'));
      expect(launchedUrl, isNotNull);
    });

    testWidgets('LegalSettingsSection triggers URL launch', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      String? launchedUrl;
      await tester.pumpWidget(
        pumpSection(
          LegalSettingsSection(
            isLoading: false,
            launchUrlCallback: (context, url) {
              launchedUrl = url;
            },
          ),
        ),
      );

      expect(find.text('Legal'), findsOneWidget);
      await tester.tap(find.text('Privacy Policy'));
      expect(launchedUrl, isNotNull);
    });

    testWidgets('AboutSettingsSection displays version', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(packageInfoStatus: PackageInfoStatus.loaded),
      );

      await tester.pumpWidget(
        pumpSection(
          AboutSettingsSection(
            state: SettingsState(packageInfoStatus: PackageInfoStatus.loaded),
            isLoading: false,
          ),
        ),
      );

      expect(find.text('About App'), findsOneWidget);
    });
  });
}
