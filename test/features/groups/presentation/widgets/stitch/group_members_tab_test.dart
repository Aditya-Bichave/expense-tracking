import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_state.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_members_tab.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockGroupMembersBloc
    extends MockBloc<GroupMembersEvent, GroupMembersState>
    implements GroupMembersBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockGroupMembersBloc mockGroupMembersBloc;
  late MockAuthBloc mockAuthBloc;

  final user = User(
    id: 'u1',
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    appMetadata: const {},
    userMetadata: const {},
  );
  final adminMember = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.admin,
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
  final otherMember = GroupMember(
    id: 'm2',
    groupId: 'g1',
    userId: 'u2',
    role: GroupRole.member,
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  GroupMembersState buildState({
    GroupMembersStatus status = GroupMembersStatus.loaded,
    GroupMembersAction action = GroupMembersAction.none,
    List<GroupMember> members = const <GroupMember>[],
    String? message,
  }) {
    return GroupMembersState(
      status: status,
      action: action,
      members: members,
      groupId: 'g1',
      message: message,
    );
  }

  setUp(() {
    mockGroupMembersBloc = MockGroupMembersBloc();
    mockAuthBloc = MockAuthBloc();

    when(
      () => mockGroupMembersBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user));
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<GroupMembersBloc>.value(value: mockGroupMembersBloc),
          ],
          child: const GroupMembersTab(groupId: 'g1'),
        ),
      ),
    );
  }

  testWidgets('renders a loading indicator during the initial load', (
    tester,
  ) async {
    when(() => mockGroupMembersBloc.state).thenReturn(
      buildState(
        status: GroupMembersStatus.loading,
        members: const <GroupMember>[],
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('renders a retry state for blocking load errors', (tester) async {
    when(() => mockGroupMembersBloc.state).thenReturn(
      buildState(
        status: GroupMembersStatus.error,
        action: GroupMembersAction.failed,
        message: 'Failed to load members',
      ),
    );

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Error: Failed to load members'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(
      () => mockGroupMembersBloc.add(const LoadGroupMembers('g1')),
    ).called(1);
  });

  testWidgets('renders members and admin controls for other members', (
    tester,
  ) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(buildState(members: [adminMember, otherMember]));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byKey(const ValueKey('tile_groupMember_u1')), findsOneWidget);
    expect(find.byKey(const ValueKey('tile_groupMember_u2')), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('opens the options sheet for removable members', (tester) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(buildState(members: [adminMember, otherMember]));

    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Change Role'), findsOneWidget);
    expect(find.text('Remove Member'), findsOneWidget);
  });
}
