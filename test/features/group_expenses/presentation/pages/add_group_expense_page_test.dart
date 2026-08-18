import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_event.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_state.dart';
import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_state.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../helpers/pump_app.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGroupMembersBloc
    extends MockBloc<GroupMembersEvent, GroupMembersState>
    implements GroupMembersBloc {}

class MockGroupExpensesBloc
    extends MockBloc<GroupExpensesEvent, GroupExpensesState>
    implements GroupExpensesBloc {}

class _FakeGroupExpensesEvent extends Fake implements GroupExpensesEvent {}

void main() {
  late MockAuthBloc authBloc;
  late MockGroupMembersBloc membersBloc;
  late MockGroupExpensesBloc expensesBloc;

  final currentUser = User(
    id: 'u1',
    aud: 'authenticated',
    createdAt: DateTime(2024, 1, 1).toIso8601String(),
    appMetadata: const {},
    userMetadata: const {},
  );

  GroupMember member(String userId) => GroupMember(
    id: 'm-$userId',
    groupId: 'g1',
    userId: userId,
    role: GroupRole.member,
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final twoMembers = [member('u1'), member('u2')];

  final existingExpense = GroupExpense(
    id: 'e1',
    groupId: 'g1',
    createdBy: 'u1',
    title: 'Dinner',
    amount: 80,
    currency: 'USD',
    occurredAt: DateTime(2024, 2, 1),
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 2, 1),
    payers: const [ExpensePayer(userId: 'u1', amount: 80)],
    splits: const [
      ExpenseSplit(userId: 'u1', amount: 50, splitType: SplitType.exact),
      ExpenseSplit(userId: 'u2', amount: 30, splitType: SplitType.exact),
    ],
  );

  void stubMembers(List<GroupMember> members) {
    final state = GroupMembersState(
      status: GroupMembersStatus.loaded,
      action: GroupMembersAction.none,
      members: members,
      groupId: 'g1',
    );
    when(() => membersBloc.state).thenReturn(state);
  }

  setUpAll(() {
    registerFallbackValue(_FakeGroupExpensesEvent());
  });

  setUp(() {
    authBloc = MockAuthBloc();
    membersBloc = MockGroupMembersBloc();
    expensesBloc = MockGroupExpensesBloc();

    when(() => authBloc.state).thenReturn(AuthAuthenticated(currentUser));
    when(() => expensesBloc.state).thenReturn(const GroupExpensesInitial());
    stubMembers(twoMembers);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    GroupExpense? initialExpense,
    String currency = 'USD',
    bool settle = true,
  }) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: settle,
      widget: AddGroupExpensePage(
        groupId: 'g1',
        currency: currency,
        initialExpense: initialExpense,
      ),
      blocProviders: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<GroupMembersBloc>.value(value: membersBloc),
        BlocProvider<GroupExpensesBloc>.value(value: expensesBloc),
      ],
    );
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    // The submit button is the last child of a SingleChildScrollView. Once the
    // exact-split rows are shown it scrolls out of the viewport, and a plain
    // tap() would silently miss instead of failing.
    await tester.ensureVisible(find.byType(AppButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppButton));
    await tester.pump();
  }

  Future<void> enterTitleAndAmount(
    WidgetTester tester,
    String title,
    String amount,
  ) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), title);
    await tester.enterText(fields.at(1), amount);
    await tester.pump();
  }

  group('AddGroupExpensePage rendering', () {
    testWidgets('renders in create mode with the Save Expense action', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Save Expense'), findsOneWidget);
      expect(find.text('Save Changes'), findsNothing);
      // No delete action in create mode.
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('renders in edit mode prefilled from the initial expense', (
      tester,
    ) async {
      await pumpPage(tester, initialExpense: existingExpense);

      expect(find.text('Edit Expense'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // Title and amount controllers are seeded from the expense.
      expect(find.widgetWithText(TextField, 'Dinner'), findsOneWidget);
      expect(find.widgetWithText(TextField, '80.0'), findsOneWidget);
    });

    testWidgets(
      'edit mode with non-equal splits opens on the exact-amount branch',
      (tester) async {
        await pumpPage(tester, initialExpense: existingExpense);

        // Exact split rows are only built when _isSplitEqually is false, and
        // they are seeded with the stored per-member amounts.
        expect(find.widgetWithText(TextField, '50.00'), findsOneWidget);
        expect(find.widgetWithText(TextField, '30.00'), findsOneWidget);
      },
    );

    testWidgets('shows the currency in the amount label', (tester) async {
      await pumpPage(tester, currency: 'INR');
      expect(find.text('Amount (INR)'), findsOneWidget);
    });

    testWidgets('shows a members placeholder while the member list is empty', (
      tester,
    ) async {
      stubMembers(const []);
      await pumpPage(tester);

      expect(find.text('Loading members...'), findsOneWidget);
    });

    testWidgets('labels the signed-in member as "You" and others by id', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('You'), findsOneWidget);
      expect(find.text('u2'), findsOneWidget);
    });

    testWidgets('disables the submit button while an operation is in flight', (
      tester,
    ) async {
      when(() => expensesBloc.state).thenReturn(const GroupExpensesLoading());
      await pumpPage(tester, settle: false);
      await tester.pump();

      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
      expect(button.isLoading, isTrue);
    });
  });

  group('AddGroupExpensePage validation', () {
    testWidgets('rejects submission when title and amount are empty', (
      tester,
    ) async {
      await pumpPage(tester);

      await tapSubmit(tester);

      expect(find.text('Please enter title and amount'), findsOneWidget);
      verifyNever(() => expensesBloc.add(any()));
    });

    testWidgets('rejects a non-numeric amount', (tester) async {
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Taxi', 'abc');

      await tapSubmit(tester);

      expect(find.text('Please enter a valid amount'), findsOneWidget);
      verifyNever(() => expensesBloc.add(any()));
    });

    testWidgets('rejects a zero amount', (tester) async {
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Taxi', '0');

      await tapSubmit(tester);

      expect(find.text('Please enter a valid amount'), findsOneWidget);
      verifyNever(() => expensesBloc.add(any()));
    });

    testWidgets('rejects submission when the group has no members', (
      tester,
    ) async {
      stubMembers(const []);
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Taxi', '20');

      await tapSubmit(tester);

      expect(find.text('No members found in the group'), findsOneWidget);
      verifyNever(() => expensesBloc.add(any()));
    });

    testWidgets('rejects submission when payer amounts do not sum to total', (
      tester,
    ) async {
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Dinner', '100');

      // Payer row for the first member: enter a partial amount.
      final payerFields = find.widgetWithText(TextField, '0.00');
      await tester.enterText(payerFields.first, '40');
      await tester.pump();

      await tapSubmit(tester);

      expect(
        find.text('Payer amounts do not equal total amount'),
        findsOneWidget,
      );
      verifyNever(() => expensesBloc.add(any()));
    });

    testWidgets('rejects submission when exact splits do not sum to total', (
      tester,
    ) async {
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Dinner', '100');

      await tester.tap(find.text('Exact Amounts'));
      await tester.pumpAndSettle();

      // Split rows now exist; fill only part of the total.
      final splitFields = find.widgetWithText(TextField, '0.00');
      await tester.enterText(splitFields.last, '10');
      await tester.pump();

      await tapSubmit(tester);

      expect(
        find.text('Split amounts do not equal total amount'),
        findsOneWidget,
      );
      verifyNever(() => expensesBloc.add(any()));
    });
  });

  group('AddGroupExpensePage submission', () {
    testWidgets(
      'equal split dispatches AddGroupExpenseRequested with even shares',
      (tester) async {
        await pumpPage(tester);
        await enterTitleAndAmount(tester, 'Dinner', '100');

        await tester.tap(find.byType(AppButton));
        await tester.pump();

        final captured =
            verify(() => expensesBloc.add(captureAny())).captured.single
                as AddGroupExpenseRequested;
        final expense = captured.expense;

        expect(expense.title, 'Dinner');
        expect(expense.amount, 100);
        expect(expense.groupId, 'g1');
        expect(expense.currency, 'USD');
        expect(expense.createdBy, 'u1');
        // Defaults to the current user paying the whole amount.
        expect(expense.payers, [const ExpensePayer(userId: 'u1', amount: 100)]);
        // Split evenly across both members.
        expect(expense.splits, [
          const ExpenseSplit(
            userId: 'u1',
            amount: 50,
            splitType: SplitType.equal,
          ),
          const ExpenseSplit(
            userId: 'u2',
            amount: 50,
            splitType: SplitType.equal,
          ),
        ]);
      },
    );

    testWidgets('trims whitespace from the title before dispatching', (
      tester,
    ) async {
      await pumpPage(tester);
      await enterTitleAndAmount(tester, '   Taxi   ', '20');

      await tapSubmit(tester);

      final captured =
          verify(() => expensesBloc.add(captureAny())).captured.single
              as AddGroupExpenseRequested;
      expect(captured.expense.title, 'Taxi');
    });

    testWidgets('exact split dispatches the per-member amounts entered', (
      tester,
    ) async {
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Dinner', '100');

      await tester.tap(find.text('Exact Amounts'));
      await tester.pumpAndSettle();

      final splitFields = find.widgetWithText(TextField, '0.00');
      // Rows are payer(u1), payer(u2), split(u1), split(u2).
      await tester.enterText(splitFields.at(2), '70');
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, '0.00').last, '30');
      await tester.pump();

      await tapSubmit(tester);

      final captured =
          verify(() => expensesBloc.add(captureAny())).captured.single
              as AddGroupExpenseRequested;
      expect(captured.expense.splits, [
        const ExpenseSplit(
          userId: 'u1',
          amount: 70,
          splitType: SplitType.exact,
        ),
        const ExpenseSplit(
          userId: 'u2',
          amount: 30,
          splitType: SplitType.exact,
        ),
      ]);
    });

    testWidgets(
      'edit mode dispatches UpdateGroupExpenseRequested and keeps id',
      (tester) async {
        await pumpPage(tester, initialExpense: existingExpense);

        await tapSubmit(tester);

        final captured =
            verify(() => expensesBloc.add(captureAny())).captured.single
                as UpdateGroupExpenseRequested;
        expect(captured.expense.id, 'e1');
        expect(captured.expense.createdBy, 'u1');
        expect(captured.expense.occurredAt, DateTime(2024, 2, 1));
        expect(captured.expense.createdAt, DateTime(2024, 2, 1));
      },
    );

    testWidgets('does nothing when the user is not authenticated', (
      tester,
    ) async {
      when(() => authBloc.state).thenReturn(AuthUnauthenticated());
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Dinner', '100');

      await tapSubmit(tester);

      verifyNever(() => expensesBloc.add(any()));
    });

    testWidgets('clearing a payer amount removes it from the payer map', (
      tester,
    ) async {
      await pumpPage(tester);
      await enterTitleAndAmount(tester, 'Dinner', '100');

      final payerField = find.widgetWithText(TextField, '0.00').first;
      await tester.enterText(payerField, '100');
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(2), '0');
      await tester.pump();

      await tapSubmit(tester);

      // With the payer map emptied, submit falls back to "current user pays
      // everything" rather than failing the payer-total check.
      final captured =
          verify(() => expensesBloc.add(captureAny())).captured.single
              as AddGroupExpenseRequested;
      expect(captured.expense.payers, [
        const ExpensePayer(userId: 'u1', amount: 100),
      ]);
    });
  });

  group('AddGroupExpensePage delete', () {
    testWidgets('delete asks for confirmation and dispatches on confirm', (
      tester,
    ) async {
      await pumpPage(tester, initialExpense: existingExpense);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete Expense?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final captured =
          verify(() => expensesBloc.add(captureAny())).captured.single
              as DeleteGroupExpenseRequested;
      expect(captured.expenseId, 'e1');
    });

    testWidgets('delete dispatches nothing when the dialog is dismissed', (
      tester,
    ) async {
      await pumpPage(tester, initialExpense: existingExpense);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => expensesBloc.add(any()));
    });
  });

  group('AddGroupExpensePage state reactions', () {
    testWidgets('shows an error dialog when the operation fails', (
      tester,
    ) async {
      whenListen(
        expensesBloc,
        Stream<GroupExpensesState>.fromIterable([
          const GroupExpensesOperationFailed('Server rejected the expense', []),
        ]),
        initialState: const GroupExpensesInitial(),
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Server rejected the expense'), findsOneWidget);
    });
  });
}
