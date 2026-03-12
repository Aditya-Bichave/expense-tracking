import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/create_group_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockCreateGroupBloc extends MockBloc<CreateGroupEvent, CreateGroupState>
    implements CreateGroupBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockGroupsBloc extends MockBloc<GroupsEvent, GroupsState>
    implements GroupsBloc {}

void main() {
  late MockCreateGroupBloc mockCreateGroupBloc;
  late MockAuthBloc mockAuthBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockGroupsBloc mockGroupsBloc;

  final testUser = User(
    id: 'test-user-id',
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    appMetadata: const {},
    userMetadata: const {},
  );
  final initialGroup = GroupEntity(
    id: 'g1',
    name: 'Home Base',
    type: GroupType.home,
    currency: 'INR',
    createdBy: 'owner',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
  );

  setUpAll(() {
    registerFallbackValue(
      const CreateGroupSubmitted(
        name: 'dummy',
        userId: 'dummy',
        type: GroupType.trip,
        currency: 'USD',
      ),
    );
  });

  setUp(() {
    mockCreateGroupBloc = MockCreateGroupBloc();
    mockAuthBloc = MockAuthBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockGroupsBloc = MockGroupsBloc();

    when(
      () => mockCreateGroupBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(testUser));
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockSettingsBloc.state,
    ).thenReturn(const SettingsState(selectedCountryCode: 'GB'));
    when(() => mockGroupsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockGroupsBloc.state).thenReturn(const GroupsLoaded([]));

    if (sl.isRegistered<CreateGroupBloc>()) {
      sl.unregister<CreateGroupBloc>();
    }
    sl.registerFactory<CreateGroupBloc>(() => mockCreateGroupBloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestWidget({CreateGroupPage? page}) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
          BlocProvider<GroupsBloc>.value(value: mockGroupsBloc),
        ],
        child: page ?? const CreateGroupPage(),
      ),
    );
  }

  Finder nameField() => find.descendant(
    of: find.byKey(const ValueKey('field_groupForm_name')),
    matching: find.byType(EditableText),
  );

  testWidgets('renders create mode and initializes currency from settings', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Create New Group'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('button_groupForm_pickPhoto')),
      findsOneWidget,
    );
    expect(find.text('Create Group'), findsOneWidget);
    expect(find.textContaining('GBP'), findsOneWidget);
  });

  testWidgets('shows validation and does not submit when name is blank', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('button_groupForm_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name'), findsOneWidget);
    verifyNever(() => mockCreateGroupBloc.add(any()));
  });

  testWidgets('dispatches CreateGroupSubmitted when valid and authenticated', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(nameField(), 'Trip Crew');
    await tester.tap(find.byKey(const ValueKey('button_groupForm_submit')));
    await tester.pump();

    final captured =
        verify(() => mockCreateGroupBloc.add(captureAny())).captured.single
            as CreateGroupSubmitted;
    expect(captured.name, 'Trip Crew');
    expect(captured.userId, 'test-user-id');
    expect(captured.currency, 'GBP');
    expect(captured.isEdit, isFalse);
  });

  testWidgets('prefills edit mode and preserves identifiers on submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(
        page: CreateGroupPage(
          groupId: initialGroup.id,
          initialGroup: initialGroup,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Group'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Home Base'), findsOneWidget);
    expect(find.textContaining('INR'), findsOneWidget);

    await tester.enterText(nameField(), 'Home Base Updated');
    await tester.tap(find.byKey(const ValueKey('button_groupForm_submit')));
    await tester.pump();

    final captured =
        verify(() => mockCreateGroupBloc.add(captureAny())).captured.single
            as CreateGroupSubmitted;
    expect(captured.groupId, initialGroup.id);
    expect(captured.createdBy, initialGroup.createdBy);
    expect(captured.createdAt, initialGroup.createdAt);
    expect(captured.existingPhotoUrl, isNull);
    expect(captured.name, 'Home Base Updated');
    expect(captured.isEdit, isTrue);
  });

  testWidgets(
    'resolves edit mode data from GroupsBloc when only groupId is provided',
    (tester) async {
      when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([initialGroup]));

      await tester.pumpWidget(
        buildTestWidget(page: const CreateGroupPage(groupId: 'g1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Group'), findsOneWidget);
      expect(find.text('Home Base'), findsOneWidget);
      expect(find.textContaining('INR'), findsOneWidget);
    },
  );

  testWidgets('shows a loading state while the edit target is still loading', (
    tester,
  ) async {
    when(() => mockGroupsBloc.state).thenReturn(const GroupsLoading());

    await tester.pumpWidget(
      buildTestWidget(page: const CreateGroupPage(groupId: 'missing')),
    );
    await tester.pump();

    expect(find.text('Edit Group'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error when the edit target cannot be found', (
    tester,
  ) async {
    when(() => mockGroupsBloc.state).thenReturn(const GroupsLoaded([]));

    await tester.pumpWidget(
      buildTestWidget(page: const CreateGroupPage(groupId: 'missing')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load this group for editing.'), findsOneWidget);
  });

  testWidgets('shows an auth error instead of dispatching when logged out', (
    tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(nameField(), 'Trip Crew');
    await tester.tap(find.byKey(const ValueKey('button_groupForm_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('You must be logged in to create a group.'),
      findsOneWidget,
    );
    verifyNever(() => mockCreateGroupBloc.add(any()));
  });
}
