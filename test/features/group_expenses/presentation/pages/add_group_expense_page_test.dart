import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockGroupExpensesBloc
    extends MockBloc<GroupExpensesEvent, GroupExpensesState>
    implements GroupExpensesBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockGroupExpensesBloc mockGroupExpensesBloc;
  late MockCategoryManagementBloc mockCategoryManagementBloc;

  final user = User(
    id: 'u1',
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    appMetadata: const {},
    userMetadata: const {},
  );

  setUpAll(() {
    registerFallbackValue(
      AddGroupExpenseRequested(
        GroupExpense(
          id: 'fallback',
          groupId: 'g1',
          createdBy: 'u1',
          title: 'Fallback',
          amount: 1,
          currency: 'INR',
          occurredAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          payers: const [],
          splits: const [],
        ),
      ),
    );
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockGroupExpensesBloc = MockGroupExpensesBloc();
    mockCategoryManagementBloc = MockCategoryManagementBloc();

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user));
    when(
      () => mockGroupExpensesBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
    when(
      () => mockCategoryManagementBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockCategoryManagementBloc.state).thenReturn(
      CategoryManagementState(status: CategoryManagementStatus.loaded),
    );
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<GroupExpensesBloc>.value(value: mockGroupExpensesBloc),
          BlocProvider<CategoryManagementBloc>.value(
            value: mockCategoryManagementBloc,
          ),
        ],
        child: const AddGroupExpensePage(groupId: 'g1', groupCurrency: 'INR'),
      ),
    );
  }

  testWidgets('renders the add expense form', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Add Group Expense'), findsOneWidget);
    expect(find.byKey(const Key('group_expense_title_field')), findsOneWidget);
    expect(find.byKey(const Key('group_expense_amount_field')), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('shows validation errors for blank and invalid values', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please enter a valid amount'), findsOneWidget);
    verifyNever(() => mockGroupExpensesBloc.add(any()));
  });

  testWidgets('dispatches AddGroupExpenseRequested with the group currency', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(
      find.byKey(const Key('group_expense_title_field')),
      'Lunch',
    );
    await tester.enterText(
      find.byKey(const Key('group_expense_amount_field')),
      '50',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    final captured =
        verify(() => mockGroupExpensesBloc.add(captureAny())).captured.single
            as AddGroupExpenseRequested;
    expect(captured.expense.groupId, 'g1');
    expect(captured.expense.title, 'Lunch');
    expect(captured.expense.amount, 50);
    expect(captured.expense.currency, 'INR');
    expect(captured.expense.createdBy, 'u1');
  });

  testWidgets(
    'shows an auth error and does not dispatch when unauthenticated',
    (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());

      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(
        find.byKey(const Key('group_expense_title_field')),
        'Lunch',
      );
      await tester.enterText(
        find.byKey(const Key('group_expense_amount_field')),
        '50',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(
        find.text('You must be logged in to add a group expense.'),
        findsOneWidget,
      );
      verifyNever(() => mockGroupExpensesBloc.add(any()));
    },
  );
}
