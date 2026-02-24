import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart' as app_auth_state;
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart'; // Import AuthEvent
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart'; // Import GroupType
import 'package:expense_tracker/features/groups/presentation/pages/create_group_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For User

// Mock AuthState using the app's state, not gotrue's
class MockCreateGroupBloc extends MockBloc<CreateGroupEvent, CreateGroupState>
    implements CreateGroupBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, app_auth_state.AuthState> implements AuthBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockUser extends Mock implements User {
  @override
  String get id => 'test-user-id';
}

void main() {
  late MockCreateGroupBloc mockCreateGroupBloc;
  late MockAuthBloc mockAuthBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUpAll(() {
    registerFallbackValue(CreateGroupSubmitted(name: 'dummy', userId: 'dummy', type: GroupType.trip, currency: 'USD'));
  });

  setUp(() {
    mockCreateGroupBloc = MockCreateGroupBloc();
    mockAuthBloc = MockAuthBloc();
    mockSettingsBloc = MockSettingsBloc();

    final sl = GetIt.instance;
    sl.reset();
    sl.registerFactory<CreateGroupBloc>(() => mockCreateGroupBloc);
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => mockAuthBloc),
        BlocProvider<SettingsBloc>(create: (_) => mockSettingsBloc),
      ],
      child: const MaterialApp(home: CreateGroupPage()),
    );
  }

  testWidgets('renders correctly', (tester) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.state)
        .thenReturn(app_auth_state.AuthAuthenticated(MockUser())); // Authenticated
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Create New Group'), findsOneWidget);
    expect(find.text('Group Name'), findsOneWidget);
    expect(find.text('Group Type'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Create Group'), findsOneWidget);
  });

  testWidgets('initializes currency from settings', (tester) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.state).thenReturn(app_auth_state.AuthAuthenticated(MockUser()));
    when(() => mockSettingsBloc.state).thenReturn(
      const SettingsState(selectedCountryCode: 'GB'),
    ); // UK -> GBP

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify initial currency is GBP (UK)
    final dropdownFinder = find.widgetWithText(
      DropdownButtonFormField<String>,
      'GBP',
    );
    expect(find.text('GBP (£)'), findsOneWidget);
  });

  testWidgets('shows error snackbar when not authenticated', (tester) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.state).thenReturn(app_auth_state.AuthUnauthenticated());
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextFormField), 'Test Group');
    await tester.tap(find.text('Create Group'));
    await tester.pump();

    expect(
      find.text('You must be logged in to create a group.'),
      findsOneWidget,
    );
    verifyNever(() => mockCreateGroupBloc.add(any()));
  });

  testWidgets('adds CreateGroupSubmitted event when valid and authenticated', (
    tester,
  ) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.state).thenReturn(app_auth_state.AuthAuthenticated(MockUser()));
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextFormField), 'Test Group');
    await tester.pumpAndSettle();

    final createButton = find.widgetWithText(ElevatedButton, 'Create Group');
    // Ensure visibility by scrolling if needed
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();

    // Tap it
    await tester.tap(createButton);
    await tester.pump();

    // Capture the argument
    final captured = verify(() => mockCreateGroupBloc.add(captureAny())).captured;

    // Manual assertions on the captured event
    expect(captured.length, 1);
    final event = captured.first;
    expect(event, isA<CreateGroupSubmitted>());
    if (event is CreateGroupSubmitted) {
        expect(event.name, 'Test Group');
        expect(event.userId, 'test-user-id');
    }
  });
}
