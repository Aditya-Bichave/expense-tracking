import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:expense_tracker/features/groups/presentation/pages/create_group_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateGroupBloc extends MockBloc<CreateGroupEvent, CreateGroupState>
    implements CreateGroupBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class FakeCreateGroupEvent extends Fake implements CreateGroupEvent {}

void main() {
  late MockCreateGroupBloc mockCreateGroupBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(FakeCreateGroupEvent());
  });

  setUp(() {
    mockCreateGroupBloc = MockCreateGroupBloc();
    mockAuthBloc = MockAuthBloc();

    if (sl.isRegistered<CreateGroupBloc>()) {
      sl.unregister<CreateGroupBloc>();
    }
    sl.registerFactory<CreateGroupBloc>(() => mockCreateGroupBloc);
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const CreateGroupPage(),
      ),
    );
  }

  final tUser = User(
    id: 'usr1',
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    appMetadata: {},
    userMetadata: {},
  );

  testWidgets('renders CreateGroupPage components', (tester) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Create New Group'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<GroupType>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('shows validation error when form is empty', (tester) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.text('Create Group'));
    await tester.pump();

    expect(find.text('Please enter a name'), findsOneWidget);
    verifyNever(() => mockCreateGroupBloc.add(any()));
  });

  testWidgets('submits form when valid', (tester) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupInitial());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(find.byType(TextFormField), 'My Vacation');
    await tester.pump();

    await tester.tap(find.text('Create Group'));
    await tester.pump();

    verify(
      () => mockCreateGroupBloc.add(any(that: isA<CreateGroupSubmitted>())),
    ).called(1);
  });

  testWidgets('shows loading indicator when state is CreateGroupLoading', (
    tester,
  ) async {
    when(() => mockCreateGroupBloc.state).thenReturn(CreateGroupLoading());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows SnackBar on failure', (tester) async {
    whenListen(
      mockCreateGroupBloc,
      Stream.fromIterable([
        CreateGroupInitial(),
        const CreateGroupFailure('Error creating group'),
      ]),
      initialState: CreateGroupInitial(),
    );
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(tUser));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Error creating group'), findsOneWidget);
  });
}
