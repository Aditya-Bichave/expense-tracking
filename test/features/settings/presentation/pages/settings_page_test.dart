import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockDataManagementBloc
    extends MockBloc<DataManagementEvent, DataManagementState>
    implements DataManagementBloc {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSettingsBloc mockSettingsBloc;
  late MockDataManagementBloc mockDataManagementBloc;
  late MockAuthBloc mockAuthBloc;
  late MockSecureStorageService mockSecureStorageService;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    mockDataManagementBloc = MockDataManagementBloc();
    mockAuthBloc = MockAuthBloc();
    mockSecureStorageService = MockSecureStorageService();

    // Register MockSecureStorageService in GetIt
    if (sl.isRegistered<SecureStorageService>()) {
      sl.unregister<SecureStorageService>();
    }
    sl.registerSingleton<SecureStorageService>(mockSecureStorageService);

    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(
      () => mockSecureStorageService.isBiometricEnabled(),
    ).thenAnswer((_) async => false);
  });

  tearDown(() {
    sl.reset();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<DataManagementBloc>.value(value: mockDataManagementBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    );
  }

  group('SettingsPage Tests', () {
    testWidgets('renders loading state when initial', (tester) async {
      when(
        () => mockSettingsBloc.state,
      ).thenReturn(const SettingsState(status: SettingsStatus.initial));
      when(
        () => mockDataManagementBloc.state,
      ).thenReturn(const DataManagementState());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders sections when loaded', (tester) async {
      // Set a large surface size to ensure all widgets are rendered without scrolling
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(
        () => mockSettingsBloc.state,
      ).thenReturn(const SettingsState(status: SettingsStatus.loaded));
      when(
        () => mockDataManagementBloc.state,
      ).thenReturn(const DataManagementState());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);

      expect(find.text('DATA MANAGEMENT'), findsOneWidget);
      expect(find.text('HELP & FEEDBACK'), findsOneWidget);
      expect(find.text('LEGAL'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('shows loading overlay when data management is loading', (
      tester,
    ) async {
      when(
        () => mockSettingsBloc.state,
      ).thenReturn(const SettingsState(status: SettingsStatus.loaded));
      when(() => mockDataManagementBloc.state).thenReturn(
        const DataManagementState(status: DataManagementStatus.loading),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Pump frame

      expect(find.text('Processing data...'), findsOneWidget);
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      ); // One in overlay
    });

    testWidgets('shows snackbar on settings error', (tester) async {
      whenListen(
        mockSettingsBloc,
        Stream.fromIterable([
          const SettingsState(
            status: SettingsStatus.error,
            errorMessage: 'Settings Error',
          ),
        ]),
        initialState: const SettingsState(),
      );
      when(
        () => mockDataManagementBloc.state,
      ).thenReturn(const DataManagementState());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Settings Error: Settings Error'), findsOneWidget);
    });

    testWidgets('shows snackbar on data management message', (tester) async {
      when(
        () => mockSettingsBloc.state,
      ).thenReturn(const SettingsState(status: SettingsStatus.loaded));
      whenListen(
        mockDataManagementBloc,
        Stream.fromIterable([
          const DataManagementState(
            status: DataManagementStatus.success,
            message: 'Backup Successful',
          ),
        ]),
        initialState: const DataManagementState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Backup Successful'), findsOneWidget);
    });
  });
}
