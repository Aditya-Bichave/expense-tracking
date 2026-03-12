import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/pages/group_list_page.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsBloc extends MockBloc<GroupsEvent, GroupsState>
    implements GroupsBloc {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockGroupsBloc mockGroupsBloc;
  late MockSyncService mockSyncService;
  late StreamController<SyncServiceStatus> syncStatusController;

  setUp(() {
    mockGroupsBloc = MockGroupsBloc();
    mockSyncService = MockSyncService();
    syncStatusController = StreamController<SyncServiceStatus>.broadcast();

    when(
      () => mockSyncService.statusStream,
    ).thenAnswer((_) => syncStatusController.stream);

    if (sl.isRegistered<SyncService>()) {
      sl.unregister<SyncService>();
    }
    sl.registerFactory<SyncService>(() => mockSyncService);
  });

  tearDown(() {
    syncStatusController.close();
    sl.reset();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<GroupsBloc>.value(
        value: mockGroupsBloc,
        child: const GroupListPage(),
      ),
    );
  }

  Widget buildRouterTestWidget({String initialLocation = '/groups'}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/groups',
          name: RouteNames.groups,
          builder: (context, state) => BlocProvider<GroupsBloc>.value(
            value: mockGroupsBloc,
            child: const GroupListPage(),
          ),
          routes: [
            GoRoute(
              path: 'create',
              name: RouteNames.groupCreate,
              builder: (context, state) =>
                  const Scaffold(body: Text('Create Group Route')),
            ),
            GoRoute(
              path: ':id',
              name: RouteNames.groupDetail,
              builder: (context, state) =>
                  Scaffold(body: Text('Group ${state.pathParameters['id']}')),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  final tGroup = GroupEntity(
    id: 'grp1',
    name: 'Trip to Paris',
    type: GroupType.trip,
    currency: 'EUR',
    createdBy: 'usr1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isArchived: false,
  );

  testWidgets('renders loading state correctly', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoading());

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when groups list is empty', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded(const []));

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('No groups yet.'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('renders list of groups when loaded', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Trip to Paris'), findsOneWidget);
    expect(find.text('TRIP'), findsOneWidget);
  });

  testWidgets('renders error state correctly', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsError('Failed to load'));

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Error: Failed to load'), findsOneWidget);
  });

  testWidgets('sync status icon updates based on stream', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded(const []));

    await tester.pumpWidget(buildTestWidget());

    // Initial is synced
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);

    syncStatusController.add(SyncServiceStatus.syncing);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_upload), findsOneWidget);

    syncStatusController.add(SyncServiceStatus.offline);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);

    syncStatusController.add(SyncServiceStatus.error);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('empty state create action navigates to create route', (
    tester,
  ) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded(const []));

    await tester.pumpWidget(buildRouterTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create one'));
    await tester.pumpAndSettle();

    expect(find.text('Create Group Route'), findsOneWidget);
  });

  testWidgets('group tile navigates to detail route', (tester) async {
    when(() => mockGroupsBloc.state).thenReturn(GroupsLoaded([tGroup]));

    await tester.pumpWidget(buildRouterTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tile_group_grp1')));
    await tester.pumpAndSettle();

    expect(find.text('Group grp1'), findsOneWidget);
  });
}
