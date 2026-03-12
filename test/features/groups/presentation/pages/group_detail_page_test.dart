import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/group_detail_page.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockGroupsBloc extends MockBloc<GroupsEvent, GroupsState>
    implements GroupsBloc {}

class MockGroupMembersBloc
    extends MockBloc<GroupMembersEvent, GroupMembersState>
    implements GroupMembersBloc {}

class MockGroupExpensesBloc
    extends MockBloc<GroupExpensesEvent, GroupExpensesState>
    implements GroupExpensesBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGroupsBloc mockGroupsBloc;
  late MockGroupMembersBloc mockGroupMembersBloc;
  late MockGroupExpensesBloc mockGroupExpensesBloc;
  late MockAuthBloc mockAuthBloc;

  final user = User(
    id: 'u1',
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    appMetadata: const {},
    userMetadata: const {},
  );
  final group = GroupEntity(
    id: 'g1',
    name: 'Test Group',
    type: GroupType.trip,
    currency: 'INR',
    createdBy: 'owner',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
  );
  final adminMember = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.admin,
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
  final memberUser = GroupMember(
    id: 'm2',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.member,
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
  final viewerMember = GroupMember(
    id: 'm3',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.viewer,
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  GroupMembersState membersState({
    List<GroupMember> members = const <GroupMember>[],
    GroupMembersAction action = GroupMembersAction.none,
    String? message,
    String? inviteUrl,
  }) {
    return GroupMembersState(
      status: GroupMembersStatus.loaded,
      action: action,
      members: members,
      groupId: 'g1',
      message: message,
      inviteUrl: inviteUrl,
    );
  }

  setUp(() {
    mockGroupsBloc = MockGroupsBloc();
    mockGroupMembersBloc = MockGroupMembersBloc();
    mockGroupExpensesBloc = MockGroupExpensesBloc();
    mockAuthBloc = MockAuthBloc();

    when(() => mockGroupsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([group]));
    when(
      () => mockGroupMembersBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(membersState(members: [adminMember]));
    when(
      () => mockGroupExpensesBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockGroupExpensesBloc.state,
    ).thenReturn(const GroupExpensesLoaded([]));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user));

    if (sl.isRegistered<GroupExpensesBloc>()) {
      sl.unregister<GroupExpensesBloc>();
    }
    if (sl.isRegistered<GroupMembersBloc>()) {
      sl.unregister<GroupMembersBloc>();
    }
    sl.registerFactory<GroupExpensesBloc>(() => mockGroupExpensesBloc);
    sl.registerFactory<GroupMembersBloc>(() => mockGroupMembersBloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestWidget() {
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
          routes: [
            GoRoute(
              path: 'edit',
              name: RouteNames.groupEdit,
              builder: (context, state) =>
                  const Scaffold(body: Text('Edit Group Screen')),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows invite and add-expense actions for admins', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Test Group'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('button_groupDetail_invite')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('button_groupDetail_settings')),
      findsOneWidget,
    );
    expect(find.byType(AppFAB), findsOneWidget);
  });

  testWidgets('hides invite and add-expense actions for viewers', (
    tester,
  ) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(membersState(members: [viewerMember]));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('button_groupDetail_invite')),
      findsNothing,
    );
    expect(find.byType(AppFAB), findsNothing);
  });

  testWidgets('opens admin actions and navigates to the edit route', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('button_groupDetail_settings')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('button_groupDetail_edit')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('button_groupDetail_leave')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('button_groupDetail_delete')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('button_groupDetail_edit')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Group Screen'), findsOneWidget);
  });

  testWidgets('confirms leave and dispatches LeaveCurrentGroup for members', (
    tester,
  ) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(membersState(members: [memberUser]));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('button_groupDetail_settings')));
    await tester.pumpAndSettle();
    expect(find.text('View Group Info'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('button_groupDetail_leave')));
    await tester.pumpAndSettle();
    expect(find.text('Leave group?'), findsOneWidget);

    await tester.tap(find.text('Leave Group'));
    await tester.pumpAndSettle();

    verify(
      () => mockGroupMembersBloc.add(
        const LeaveCurrentGroup(groupId: 'g1', userId: 'u1'),
      ),
    ).called(1);
  });

  testWidgets('renders expense rows with the current group currency', (
    tester,
  ) async {
    when(() => mockGroupExpensesBloc.state).thenReturn(
      GroupExpensesLoaded([
        GroupExpense(
          id: 'e1',
          groupId: 'g1',
          createdBy: 'u1',
          title: 'Lunch',
          amount: 42,
          currency: 'USD',
          occurredAt: DateTime(2024, 1, 2),
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
          payers: const [],
          splits: const [],
        ),
      ]),
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tile_groupExpense_e1')), findsOneWidget);
    expect(find.text('42.00 INR'), findsOneWidget);
  });

  testWidgets('shows an empty expense state when the group has no expenses', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No expenses yet.'), findsOneWidget);
  });

  testWidgets('shows an expense error and retries loading when asked', (
    tester,
  ) async {
    when(
      () => mockGroupExpensesBloc.state,
    ).thenReturn(const GroupExpensesError('Network down'));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    clearInteractions(mockGroupExpensesBloc);

    expect(find.text('Error: Network down'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    verify(
      () => mockGroupExpensesBloc.add(const LoadGroupExpenses('g1')),
    ).called(1);
  });

  testWidgets(
    'tapping an expense shows the placeholder edit feedback for members',
    (tester) async {
      when(
        () => mockGroupMembersBloc.state,
      ).thenReturn(membersState(members: [memberUser]));
      when(() => mockGroupExpensesBloc.state).thenReturn(
        GroupExpensesLoaded([
          GroupExpense(
            id: 'e1',
            groupId: 'g1',
            createdBy: 'u1',
            title: 'Lunch',
            amount: 42,
            currency: 'USD',
            occurredAt: DateTime(2024, 1, 2),
            createdAt: DateTime(2024, 1, 2),
            updatedAt: DateTime(2024, 1, 2),
            payers: const [],
            splits: const [],
          ),
        ]),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tile_groupExpense_e1')));
      await tester.pumpAndSettle();

      expect(find.text('Edit expense coming soon'), findsOneWidget);
    },
  );

  testWidgets('non-admin settings can open the group info dialog', (
    tester,
  ) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(membersState(members: [memberUser]));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('button_groupDetail_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Group Info'));
    await tester.pumpAndSettle();

    expect(find.text('Group Info'), findsOneWidget);
    expect(find.text('Name: Test Group\nRole: MEMBER'), findsOneWidget);
  });

  testWidgets('sole-admin leave confirmation dispatches group deletion', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('button_groupDetail_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('button_groupDetail_leave')));
    await tester.pumpAndSettle();

    expect(find.text('Delete group?'), findsOneWidget);
    await tester.tap(find.text('Delete Group').last);
    await tester.pumpAndSettle();

    verify(
      () => mockGroupMembersBloc.add(const DeleteCurrentGroup(groupId: 'g1')),
    ).called(1);
  });

  testWidgets('delete action confirms and dispatches DeleteCurrentGroup', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('button_groupDetail_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('button_groupDetail_delete')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This permanently removes the group, members, invites, and group expenses.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete Group').last);
    await tester.pumpAndSettle();

    verify(
      () => mockGroupMembersBloc.add(const DeleteCurrentGroup(groupId: 'g1')),
    ).called(1);
  });

  testWidgets(
    'shows an auth error when an unauthenticated user tries to leave',
    (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('button_groupDetail_settings')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('button_groupDetail_leave')));
      await tester.pumpAndSettle();

      expect(
        find.text('You must be logged in to manage this group.'),
        findsOneWidget,
      );
    },
  );
}
