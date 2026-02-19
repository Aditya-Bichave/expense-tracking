import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockDataManagementBloc
    extends MockBloc<DataManagementEvent, DataManagementState>
    implements DataManagementBloc {}

void main() {
  late MockSettingsBloc mockSettingsBloc;
  late MockDataManagementBloc mockDataManagementBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    mockDataManagementBloc = MockDataManagementBloc();
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<DataManagementBloc>.value(value: mockDataManagementBloc),
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
      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.initial),
      );
      when(() => mockDataManagementBloc.state).thenReturn(
        const DataManagementState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders sections when loaded', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded),
      );
      when(() => mockDataManagementBloc.state).thenReturn(
        const DataManagementState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('SECURITY'), findsOneWidget);
      // Data Management Section
      await tester.scrollUntilVisible(
        find.text('DATA MANAGEMENT'),
        500.0,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('DATA MANAGEMENT'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('HELP & FEEDBACK'),
        500.0,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('HELP & FEEDBACK'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('LEGAL'),
        500.0,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('LEGAL'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('ABOUT'),
        500.0,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('shows loading overlay when data management is loading', (
      tester,
    ) async {
      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded),
      );
      when(() => mockDataManagementBloc.state).thenReturn(
        const DataManagementState(status: DataManagementStatus.loading),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Pump frame

      expect(find.text('Processing data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget); // One in overlay
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
      when(() => mockDataManagementBloc.state).thenReturn(
        const DataManagementState(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Settings Error: Settings Error'), findsOneWidget);
    });

    testWidgets('shows snackbar on data management message', (tester) async {
      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(status: SettingsStatus.loaded),
      );
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
