import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_members_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGroupMembersBloc
    extends MockBloc<GroupMembersEvent, GroupMembersState>
    implements GroupMembersBloc {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockGroupMembersBloc mockGroupMembersBloc;
  late MockUser mockUser;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockGroupMembersBloc = MockGroupMembersBloc();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user1');
  });

  Widget createWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<GroupMembersBloc>.value(value: mockGroupMembersBloc),
      ],
      child: const MaterialApp(home: Scaffold(body: GroupMembersTab())),
    );
  }

  testWidgets('GroupMembersTab shows loading indicator when loading', (
    WidgetTester tester,
  ) async {
    when(() => mockGroupMembersBloc.state).thenReturn(GroupMembersLoading());
    await tester.pumpWidget(createWidget());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('GroupMembersTab shows members list when loaded', (
    WidgetTester tester,
  ) async {
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(mockUser));

    final members = [
      GroupMember(
        id: 'm1',
        groupId: 'g1',
        userId: 'user1',
        role: GroupRole.admin,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      GroupMember(
        id: 'm2',
        groupId: 'g1',
        userId: 'user2',
        role: GroupRole.member,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded(members));

    await tester.pumpWidget(createWidget());

    expect(find.text('admin (You)'), findsOneWidget);
    expect(find.text('member '), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('GroupMembersTab shows error message when error', (
    WidgetTester tester,
  ) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(const GroupMembersError('Failed to load'));
    await tester.pumpWidget(createWidget());
    expect(find.text('Error: Failed to load'), findsOneWidget);
  });
}
