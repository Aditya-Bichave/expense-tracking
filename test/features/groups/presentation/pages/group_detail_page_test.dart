import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/group_detail_page.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  setUp(() {
    mockGroupsBloc = MockGroupsBloc();
    mockGroupMembersBloc = MockGroupMembersBloc();
    mockGroupExpensesBloc = MockGroupExpensesBloc();
    mockAuthBloc = MockAuthBloc();

    if (sl.isRegistered<GroupExpensesBloc>())
      sl.unregister<GroupExpensesBloc>();
    if (sl.isRegistered<GroupMembersBloc>()) sl.unregister<GroupMembersBloc>();

    sl.registerFactory<GroupExpensesBloc>(() => mockGroupExpensesBloc);
    sl.registerFactory<GroupMembersBloc>(() => mockGroupMembersBloc);
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<GroupsBloc>.value(value: mockGroupsBloc),
          ],
          child: const GroupDetailPage(groupId: 'g1'),
        ),
      ),
    );
  }

  final tUser = User(
    id: 'u1',
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    appMetadata: {},
    userMetadata: {},
  );
  final tGroup = GroupEntity(
    id: 'g1',
    name: 'Test Group',
    type: GroupType.trip,
    currency: 'USD',
    createdBy: 'u0',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isArchived: false,
  );
  final tMemberAdmin = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.admin,
    joinedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  final tMemberViewer = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.viewer,
    joinedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('renders group name from GroupsBloc', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));
    when(() => mockGroupMembersBloc.state).thenReturn(GroupMembersInitial());
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Test Group'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('renders default group name when group not found in state', (
    tester,
  ) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded(const []));
    when(() => mockGroupMembersBloc.state).thenReturn(GroupMembersInitial());
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Group'), findsOneWidget); // Default name
  });

  testWidgets('shows add expense FAB if user is not viewer', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberAdmin]));
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(AppFAB), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('hides add expense FAB if user is viewer', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberViewer]));
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(AppFAB), findsNothing);
  });

  testWidgets('shows invite member icon if user is admin', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberAdmin]));
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byIcon(Icons.person_add), findsOneWidget);
  });

  testWidgets('hides invite member icon if user is not admin', (tester) async {
    final tMemberRegular = GroupMember(
      id: 'm1',
      groupId: 'g1',
      userId: 'u1',
      role: GroupRole.member,
      joinedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberRegular]));
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byIcon(Icons.person_add), findsNothing);
  });

  testWidgets('opens invite sheet when invite icon is tapped', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberAdmin]));
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    expect(find.text('Invite Members'), findsOneWidget);
  });
}
