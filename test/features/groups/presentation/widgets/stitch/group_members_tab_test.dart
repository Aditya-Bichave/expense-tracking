import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_members_tab.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
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

  setUp(() {
    mockGroupMembersBloc = MockGroupMembersBloc();
    mockAuthBloc = MockAuthBloc();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<GroupMembersBloc>.value(value: mockGroupMembersBloc),
          ],
          child: const GroupMembersTab(),
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

  final tMemberAdmin = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.admin,
    joinedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final tMemberOther = GroupMember(
    id: 'm2',
    groupId: 'g1',
    userId: 'u2',
    role: GroupRole.member,
    joinedAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('renders loading indicator when loading', (tester) async {
    when(() => mockGroupMembersBloc.state).thenReturn(GroupMembersLoading());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('renders empty message when no members', (tester) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded(const []));
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('No members loaded'), findsOneWidget);
  });

  testWidgets('renders members list when loaded', (tester) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberAdmin, tMemberOther]));
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(AppListTile), findsNWidgets(2));
    expect(find.text('admin (You)'), findsOneWidget);
    expect(find.text('member '), findsOneWidget);
  });

  testWidgets('shows options icon for other members if current user is admin', (
    tester,
  ) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberAdmin, tMemberOther]));
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    // Should find at least one icon button (for the other member)
    // The current user (admin) should NOT have an option button for themselves
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('opens options sheet when icon tapped', (tester) async {
    when(
      () => mockGroupMembersBloc.state,
    ).thenReturn(GroupMembersLoaded([tMemberAdmin, tMemberOther]));
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Change Role'), findsOneWidget);
    expect(find.text('Remove Member'), findsOneWidget);
  });
}
