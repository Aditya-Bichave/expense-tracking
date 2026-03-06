import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/dead_letter_repository.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';

class MockDeadLetterRepository extends Mock implements DeadLetterRepository {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockDataManagementBloc
    extends MockBloc<DataManagementEvent, DataManagementState>
    implements DataManagementBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

void main() {
  late MockDeadLetterRepository mockDeadLetterRepository;
  late MockOutboxRepository mockOutboxRepository;
  late MockSettingsBloc mockSettingsBloc;
  late MockDataManagementBloc mockDataManagementBloc;
  late MockAuthBloc mockAuthBloc;
  late MockAccountListBloc mockAccountListBloc;

  setUp(() {
    mockDeadLetterRepository = MockDeadLetterRepository();
    mockOutboxRepository = MockOutboxRepository();

    if (sl.isRegistered<DeadLetterRepository>())
      sl.unregister<DeadLetterRepository>();
    if (sl.isRegistered<OutboxRepository>()) sl.unregister<OutboxRepository>();

    sl.registerSingleton<DeadLetterRepository>(mockDeadLetterRepository);
    sl.registerSingleton<OutboxRepository>(mockOutboxRepository);

    when(() => mockDeadLetterRepository.getItems()).thenReturn([]);
    when(() => mockOutboxRepository.getPendingItems()).thenReturn([]);
    mockSettingsBloc = MockSettingsBloc();
    mockDataManagementBloc = MockDataManagementBloc();
    mockAuthBloc = MockAuthBloc();
    mockAccountListBloc = MockAccountListBloc();

    // Setup default stream/state for all blocs
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    whenListen(mockAuthBloc, Stream.fromIterable([AuthInitial()]));

    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));
    whenListen(
      mockAccountListBloc,
      Stream.fromIterable([const AccountListLoaded(accounts: [])]),
    );

    // Default for SettingsBloc and DataManagementBloc (can be overridden in tests)
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    whenListen(mockSettingsBloc, Stream.fromIterable([const SettingsState()]));

    when(
      () => mockDataManagementBloc.state,
    ).thenReturn(const DataManagementState());
    whenListen(
      mockDataManagementBloc,
      Stream.fromIterable([const DataManagementState()]),
    );
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<DataManagementBloc>.value(value: mockDataManagementBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    );
  }

  group('SettingsPage Tests', () {
    testWidgets(skip: true, 'renders loading state when initial', (
      tester,
    ) async {
      whenListen(
        mockSettingsBloc,
        Stream.value(const SettingsState(status: SettingsStatus.initial)),
        initialState: const SettingsState(status: SettingsStatus.initial),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 8000)),
          child: createWidgetUnderTest(),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(skip: true, 'renders sections when loaded', (tester) async {
      whenListen(
        mockSettingsBloc,
        Stream.value(const SettingsState(status: SettingsStatus.loaded)),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 8000)),
          child: createWidgetUnderTest(),
        ),
      );

      await tester.pump(); // Build frame

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('SECURITY'), findsOneWidget);

      // Data Management Section - needs scrolling
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

    testWidgets(
      skip: true,
      'shows loading overlay when data management is loading',
      (tester) async {
        whenListen(
          mockSettingsBloc,
          Stream.value(const SettingsState(status: SettingsStatus.loaded)),
          initialState: const SettingsState(status: SettingsStatus.loaded),
        );
        whenListen(
          mockDataManagementBloc,
          Stream.value(
            const DataManagementState(status: DataManagementStatus.loading),
          ),
          initialState: const DataManagementState(
            status: DataManagementStatus.loading,
          ),
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(800, 8000)),
            child: createWidgetUnderTest(),
          ),
        );

        await tester.pump(); // Build frame

        expect(find.text('Processing data...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(skip: true, 'shows snackbar on settings error', (tester) async {
      whenListen(
        mockSettingsBloc,
        Stream.fromIterable([
          const SettingsState(status: SettingsStatus.loaded),
          const SettingsState(
            status: SettingsStatus.error,
            errorMessage: 'Settings Error',
          ),
        ]),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 8000)),
          child: createWidgetUnderTest(),
        ),
      );

      await tester.pump(); // Initial
      await tester.pump(); // Error state
      await tester.pump(); // SnackBar animation

      expect(find.text('Settings Error: Settings Error'), findsOneWidget);
    });

    testWidgets(skip: true, 'shows snackbar on data management message', (
      tester,
    ) async {
      whenListen(
        mockSettingsBloc,
        Stream.value(const SettingsState(status: SettingsStatus.loaded)),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );
      whenListen(
        mockDataManagementBloc,
        Stream.fromIterable([
          const DataManagementState(),
          const DataManagementState(
            status: DataManagementStatus.success,
            message: 'Backup Successful',
          ),
        ]),
        initialState: const DataManagementState(),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 8000)),
          child: createWidgetUnderTest(),
        ),
      );

      await tester.pump(); // Initial
      await tester.pump(); // Success state
      await tester.pump(); // SnackBar animation

      expect(find.text('Backup Successful'), findsOneWidget);
    });
  });

  testWidgets('shows dead letter banner when items exist', (
    tester,
  ) async {
    final item = DeadLetterModel(
      id: '1',
      table: 'x',
      operation: OpType.create,
      payload: {},
      createdAt: DateTime.now(),
      failedAt: DateTime.now(),
      lastError: 'e',
      retryCount: 0,
    );
    whenListen(
      mockSettingsBloc,
      Stream.value(const SettingsState(status: SettingsStatus.loaded)),
      initialState: const SettingsState(status: SettingsStatus.loaded),
    );

    whenListen(
      mockDataManagementBloc,
      Stream.value(const DataManagementState()),
      initialState: const DataManagementState(),
    );
    whenListen(
      mockAuthBloc,
      Stream.value(AuthInitial()),
      initialState: AuthInitial(),
    );

    whenListen(
      mockSettingsBloc,
      Stream.value(const SettingsState(status: SettingsStatus.loaded)),
      initialState: const SettingsState(status: SettingsStatus.loaded),
    );
    whenListen(
      mockDataManagementBloc,
      Stream.value(const DataManagementState()),
      initialState: const DataManagementState(),
    );
    whenListen(
      mockAuthBloc,
      Stream.value(AuthInitial()),
      initialState: AuthInitial(),
    );
    when(() => mockDeadLetterRepository.getItems()).thenReturn([item]);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 8000)),
        child: createWidgetUnderTest(),
      ),
    );

    await tester.pump();

    expect(find.text('Sync Errors Detected'), findsOneWidget);
  });

  testWidgets(
    skip: true,
    'shows confirmation dialog on logout when outbox is not empty',
    (tester) async {
      final item = SyncMutationModel(
        id: '1',
        table: 'x',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      whenListen(
        mockSettingsBloc,
        Stream.value(const SettingsState(status: SettingsStatus.loaded)),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );

      whenListen(
        mockDataManagementBloc,
        Stream.value(const DataManagementState()),
        initialState: const DataManagementState(),
      );
      whenListen(
        mockAuthBloc,
        Stream.value(AuthInitial()),
        initialState: AuthInitial(),
      );

      whenListen(
        mockSettingsBloc,
        Stream.value(const SettingsState(status: SettingsStatus.loaded)),
        initialState: const SettingsState(status: SettingsStatus.loaded),
      );
      whenListen(
        mockDataManagementBloc,
        Stream.value(const DataManagementState()),
        initialState: const DataManagementState(),
      );
      whenListen(
        mockAuthBloc,
        Stream.value(AuthInitial()),
        initialState: AuthInitial(),
      );
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 8000)),
          child: createWidgetUnderTest(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      // Because logout might be deep in the list, just tap it directly without looking
      // Actually we CAN find the icon if it's rendered.
      final logoutButton = find.byIcon(Icons.logout_rounded);

      await tester.tap(logoutButton);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Unsynced Changes'), findsOneWidget);
      expect(find.text('Force Logout'), findsOneWidget);
    },
  );
}
