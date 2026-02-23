import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../helpers/pump_app.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGroupExpensesBloc
    extends MockBloc<GroupExpensesEvent, GroupExpensesState>
    implements GroupExpensesBloc {}

class MockUser extends Mock implements User {
  @override
  String get id => '1';
}

class FakeGroupExpensesEvent extends Fake implements GroupExpensesEvent {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockGroupExpensesBloc mockGroupExpensesBloc;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(FakeGroupExpensesEvent());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockGroupExpensesBloc = MockGroupExpensesBloc();
    mockUser = MockUser();
  });

  // Use simple pumpWidget wrapper to avoid GoRouter conflicts in this specific test
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<GroupExpensesBloc>.value(value: mockGroupExpensesBloc),
        ],
        child: MaterialApp(home: const AddGroupExpensePage(groupId: '1')),
      ),
    );
  }

  testWidgets('AddGroupExpensePage renders correctly', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(mockUser));
    when(() => mockGroupExpensesBloc.state).thenReturn(GroupExpensesInitial());

    await pumpPage(tester);

    expect(find.text('Add Group Expense'), findsOneWidget);
  });

  testWidgets(
    'AddGroupExpensePage adds event when fields filled and button pressed',
    (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthAuthenticated(mockUser));
      when(
        () => mockGroupExpensesBloc.state,
      ).thenReturn(GroupExpensesInitial());

      await pumpPage(tester);

      await tester.enterText(
        find.ancestor(of: find.text('Title'), matching: find.byType(TextField)),
        'Dinner',
      );
      await tester.enterText(
        find.ancestor(
          of: find.text('Amount'),
          matching: find.byType(TextField),
        ),
        '50',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      verify(
        () => mockGroupExpensesBloc.add(
          any(that: isA<AddGroupExpenseRequested>()),
        ),
      ).called(1);
      // Cannot check navigation with simple MaterialApp easily without observer, but verifying logic executed is enough.
    },
  );
}
