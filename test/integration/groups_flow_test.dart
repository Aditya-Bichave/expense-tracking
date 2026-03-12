import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:expense_tracker/features/groups/domain/usecases/update_group.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/create_group_page.dart';
import 'package:expense_tracker/features/groups/presentation/pages/group_detail_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:uuid/uuid.dart';

class MockCreateGroup extends Mock implements CreateGroup {}

class MockUpdateGroup extends Mock implements UpdateGroup {}

class MockUuid extends Mock implements Uuid {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGroupsBloc extends MockBloc<GroupsEvent, GroupsState>
    implements GroupsBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockGroupsRepository extends Mock implements GroupsRepository {}

class MockGroupExpensesRepository extends Mock
    implements GroupExpensesRepository {}

void main() {
  late MockCreateGroup mockCreateGroup;
  late MockUpdateGroup mockUpdateGroup;
  late MockUuid mockUuid;
  late MockAuthBloc mockAuthBloc;
  late MockGroupsBloc mockGroupsBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockGroupsRepository mockGroupsRepository;
  late MockGroupExpensesRepository mockGroupExpensesRepository;

  final testUser = User(
    id: 'u1',
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    appMetadata: const {},
    userMetadata: const {},
  );
  final group = GroupEntity(
    id: 'g1',
    name: 'Weekend Trip',
    type: GroupType.trip,
    currency: 'USD',
    createdBy: 'u1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
  final member = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.member,
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(group);
  });

  setUp(() async {
    await sl.reset();

    mockCreateGroup = MockCreateGroup();
    mockUpdateGroup = MockUpdateGroup();
    mockUuid = MockUuid();
    mockAuthBloc = MockAuthBloc();
    mockGroupsBloc = MockGroupsBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockGroupsRepository = MockGroupsRepository();
    mockGroupExpensesRepository = MockGroupExpensesRepository();

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(testUser));
    when(() => mockGroupsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([group]));
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => mockSettingsBloc.state,
    ).thenReturn(const SettingsState(selectedCountryCode: 'US'));
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'Integration: Create group flow validates input and submits through the real bloc',
    (tester) async {
      when(() => mockUuid.v4()).thenReturn('new-group-id');
      when(() => mockCreateGroup(any())).thenAnswer(
        (invocation) async =>
            Right(invocation.positionalArguments.first as GroupEntity),
      );
      when(() => mockUpdateGroup(any())).thenAnswer((_) async => Right(group));

      sl.registerFactory<CreateGroupBloc>(
        () => CreateGroupBloc(
          createGroup: mockCreateGroup,
          updateGroup: mockUpdateGroup,
          uuid: mockUuid,
        ),
      );

      final router = GoRouter(
        initialLocation: '/groups/create',
        routes: [
          GoRoute(
            path: '/groups',
            builder: (context, state) =>
                const Scaffold(body: Text('Groups Home')),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                    BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
                    BlocProvider<GroupsBloc>.value(value: mockGroupsBloc),
                  ],
                  child: const CreateGroupPage(),
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_groupForm_submit')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a name'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('field_groupForm_name')),
          matching: find.byType(EditableText),
        ),
        'Mountain Crew',
      );
      await tester.tap(find.byKey(const ValueKey('button_groupForm_submit')));
      await tester.pumpAndSettle();

      final captured =
          verify(() => mockCreateGroup(captureAny())).captured.single
              as GroupEntity;
      expect(captured.id, 'new-group-id');
      expect(captured.name, 'Mountain Crew');
      expect(captured.createdBy, 'u1');
      expect(captured.currency, 'USD');
      expect(find.text('Groups Home'), findsOneWidget);
    },
  );

  testWidgets(
    'Integration: Group detail leave flow loads members and navigates back after confirmation',
    (tester) async {
      when(
        () => mockGroupsRepository.getGroupMembers('g1'),
      ).thenAnswer((_) async => Right([member]));
      when(
        () => mockGroupsRepository.leaveGroup('g1', 'u1'),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockGroupExpensesRepository.getExpenses('g1'),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockGroupExpensesRepository.syncExpenses('g1'),
      ).thenAnswer((_) async => const Right(null));

      sl.registerFactory<GroupMembersBloc>(
        () => GroupMembersBloc(mockGroupsRepository),
      );
      sl.registerFactory<GroupExpensesBloc>(
        () => GroupExpensesBloc(mockGroupExpensesRepository),
      );

      final router = GoRouter(
        initialLocation: '/groups/g1',
        routes: [
          GoRoute(
            path: '/groups',
            builder: (context, state) =>
                const Scaffold(body: Text('Groups Home')),
          ),
          GoRoute(
            path: '/groups/:id',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<GroupsBloc>.value(value: mockGroupsBloc),
              ],
              child: GroupDetailPage(groupId: state.pathParameters['id']!),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Weekend Trip'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('button_groupDetail_settings')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('button_groupDetail_leave')));
      await tester.pumpAndSettle();
      expect(find.text('Leave group?'), findsOneWidget);

      await tester.tap(find.text('Leave Group'));
      await tester.pumpAndSettle();

      verify(() => mockGroupsRepository.leaveGroup('g1', 'u1')).called(1);
      expect(find.text('Groups Home'), findsOneWidget);
    },
  );
}
