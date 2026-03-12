import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_balances.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_event.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_balances_tab.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

class MockGroupBalancesBloc extends Mock implements GroupBalancesBloc {}

class MockNudgeBloc extends Mock implements NudgeBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockUser extends Mock implements User {}

void main() {
  late MockGroupBalancesBloc mockGroupBalancesBloc;
  late MockNudgeBloc mockNudgeBloc;
  late MockAuthBloc mockAuthBloc;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(const FetchBalances('groupId'));
    registerFallbackValue(const RefreshBalances('groupId'));
    registerFallbackValue(
      SendNudge(
        groupId: 'groupId',
        debt: SimplifiedDebt(
          fromUserId: 'user123',
          toUserId: 'user456',
          amount: 100,
          fromUserName: 'You',
          toUserName: 'John',
        ),
      ),
    );
  });

  setUp(() {
    mockGroupBalancesBloc = MockGroupBalancesBloc();
    mockNudgeBloc = MockNudgeBloc();
    mockAuthBloc = MockAuthBloc();
    mockUser = MockUser();

    when(() => mockGroupBalancesBloc.stream).thenAnswer((_) => Stream.empty());
    when(() => mockNudgeBloc.stream).thenAnswer((_) => Stream.empty());
    when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.empty());

    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(mockUser));
    when(() => mockNudgeBloc.state).thenReturn(NudgeInitial());
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          final appKitTheme = AppKitTheme(
            colors: AppColors(colorScheme),
            typography: AppTypography(textTheme),
            spacing: const AppSpacing(),
            radii: const AppRadii(),
            motion: const AppMotion(),
            shadows: AppShadows(isDark: false),
          );

          return Theme(
            data: Theme.of(context).copyWith(extensions: [appKitTheme]),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<GroupBalancesBloc>.value(
                  value: mockGroupBalancesBloc,
                ),
                BlocProvider<NudgeBloc>.value(value: mockNudgeBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const Scaffold(
                body: GroupBalancesTab(groupId: 'test_group_id'),
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('renders loading state correctly', (WidgetTester tester) async {
    when(
      () => mockGroupBalancesBloc.state,
    ).thenReturn(const GroupBalancesLoading());

    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders loaded state with positive balance', (
    WidgetTester tester,
  ) async {
    final balances = GroupBalances(myNetBalance: 150, simplifiedDebts: []);

    when(
      () => mockGroupBalancesBloc.state,
    ).thenReturn(GroupBalancesLoaded(balances));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('You are owed'), findsOneWidget);
    expect(find.text('150.00 INR'), findsOneWidget);
  });

  testWidgets('renders loaded state with balances', (
    WidgetTester tester,
  ) async {
    final balances = GroupBalances(
      myNetBalance: -100,
      simplifiedDebts: [
        SimplifiedDebt(
          fromUserId: 'user123',
          toUserId: 'user456',
          amount: 100,
          fromUserName: 'You',
          toUserName: 'John',
        ),
        SimplifiedDebt(
          fromUserId: 'user789',
          toUserId: 'user123',
          amount: 50,
          fromUserName: 'Jane',
          toUserName: 'You',
        ),
      ],
    );

    when(
      () => mockGroupBalancesBloc.state,
    ).thenReturn(GroupBalancesLoaded(balances));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('You owe'), findsOneWidget);
    expect(find.text('100.00 INR'), findsOneWidget);
    expect(find.text('You owe John 100.00'), findsOneWidget);
    expect(find.text('Settle Up'), findsOneWidget);
    expect(find.text('Jane owes you 50.00'), findsOneWidget);
    expect(find.text('Nudge'), findsOneWidget);
  });

  testWidgets('renders settled up state', (WidgetTester tester) async {
    final balances = GroupBalances(myNetBalance: 0, simplifiedDebts: []);

    when(
      () => mockGroupBalancesBloc.state,
    ).thenReturn(GroupBalancesLoaded(balances));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('You are all settled up!'), findsOneWidget);
    expect(find.text('You are all settled up'), findsOneWidget); // Card title
  });

  testWidgets('taps Nudge button', (WidgetTester tester) async {
    final balances = GroupBalances(
      myNetBalance: 50,
      simplifiedDebts: [
        SimplifiedDebt(
          fromUserId: 'user789',
          toUserId: 'user123',
          amount: 50,
          fromUserName: 'Jane',
          toUserName: 'You',
        ),
      ],
    );

    when(
      () => mockGroupBalancesBloc.state,
    ).thenReturn(GroupBalancesLoaded(balances));
    when(() => mockNudgeBloc.state).thenReturn(NudgeInitial());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nudge'));
    await tester.pump();

    verify(() => mockNudgeBloc.add(any(that: isA<SendNudge>()))).called(1);
  });

  testWidgets('taps Settle Up button', (WidgetTester tester) async {
    final balances = GroupBalances(
      myNetBalance: -100,
      simplifiedDebts: [
        SimplifiedDebt(
          fromUserId: 'user123',
          toUserId: 'user456',
          amount: 100,
          fromUserName: 'You',
          toUserName: 'John',
        ),
      ],
    );

    when(
      () => mockGroupBalancesBloc.state,
    ).thenReturn(GroupBalancesLoaded(balances));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settle Up'));
    await tester.pumpAndSettle();

    // Settlement dialog should appear
    expect(find.text('Settle with John'), findsOneWidget);
  });
}
