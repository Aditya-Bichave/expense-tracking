import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockGroupExpensesBloc extends Mock implements GroupExpensesBloc {}

class MockUser extends Mock implements User {}

class FakeAddGroupExpenseRequested extends AddGroupExpenseRequested {
  FakeAddGroupExpenseRequested()
    : super(
        GroupExpense(
          id: 'id',
          groupId: 'g',
          createdBy: 'u',
          title: 't',
          amount: 0,
          currency: 'USD',
          occurredAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          payers: [],
          splits: [],
        ),
      );
}

// Fallback for abstract Event
class FakeGroupExpensesEvent extends Fake implements GroupExpensesEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockGroupExpensesBloc mockGroupExpensesBloc;

  setUpAll(() {
    registerFallbackValue(FakeAddGroupExpenseRequested());
    registerFallbackValue(FakeGroupExpensesEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockGroupExpensesBloc = MockGroupExpensesBloc();

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());

    when(
      () => mockGroupExpensesBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<GroupExpensesBloc>.value(value: mockGroupExpensesBloc),
        ],
        child: const AddGroupExpensePage(groupId: 'g1'),
      ),
    );
  }

  testWidgets('AddGroupExpensePage renders form fields', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('AddGroupExpensePage adds expense when valid', (tester) async {
    final user = MockUser();
    when(() => user.id).thenReturn('u1');
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(user));
    when(() => mockGroupExpensesBloc.add(any())).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());

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

    final captured = verify(
      () => mockGroupExpensesBloc.add(captureAny()),
    ).captured;
    final event = captured.first as AddGroupExpenseRequested;
    expect(event.expense.title, 'Lunch');
    expect(event.expense.amount, 50.0);
    expect(event.expense.groupId, 'g1');
  });
}
