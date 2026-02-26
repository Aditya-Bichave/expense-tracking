// ignore_for_file: directives_ordering

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/numpad_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockAddExpenseWizardBloc extends MockBloc<AddExpenseWizardEvent, AddExpenseWizardState> implements AddExpenseWizardBloc {}
class FakeAddExpenseWizardState extends Fake implements AddExpenseWizardState {}

void main() {
  late MockAddExpenseWizardBloc mockBloc;
  final tDate = DateTime(2023, 1, 1);

  setUpAll(() {
    registerFallbackValue(FakeAddExpenseWizardState());
    registerFallbackValue(const AmountChanged(0.0));
  });

  setUp(() {
    mockBloc = MockAddExpenseWizardBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AddExpenseWizardBloc>.value(
        value: mockBloc,
        child: NumpadScreen(onNext: () {}),
      ),
    );
  }

  group('NumpadScreen', () {
    testWidgets('renders initial amount as 0', (tester) async {
       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(currentUserId: 'u1', transactionId: 't1', expenseDate: tDate));

       await tester.pumpWidget(createWidgetUnderTest());
       // '0' is numpad key and display. findsNWidgets(2)
       expect(find.text('0'), findsNWidgets(2));
    });

    testWidgets('updates display and bloc on input', (tester) async {
       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(currentUserId: 'u1', transactionId: 't1', expenseDate: tDate));

       await tester.pumpWidget(createWidgetUnderTest());

       await tester.tap(find.text('1'));
       await tester.pump();
       // Keypad '1' + Display '1' = 2
       expect(find.text('1'), findsNWidgets(2));
       verify(() => mockBloc.add(const AmountChanged(1.0))).called(1);

       await tester.tap(find.text('5'));
       await tester.pump();
       // Keypad '5' + Display '15'
       expect(find.text('15'), findsOneWidget);
       verify(() => mockBloc.add(const AmountChanged(15.0))).called(1);
    });

    testWidgets('handles backspace', (tester) async {
       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(currentUserId: 'u1', transactionId: 't1', expenseDate: tDate));

       await tester.pumpWidget(createWidgetUnderTest());

       // Enter 12
       await tester.tap(find.text('1'));
       await tester.tap(find.text('2'));
       await tester.pump();
       expect(find.text('12'), findsOneWidget);

       // Backspace -> 1
       await tester.tap(find.byIcon(Icons.backspace_outlined));
       await tester.pump();
       // Display '1', Keypad '1' -> 2
       expect(find.text('1'), findsNWidgets(2));

       verify(() => mockBloc.add(const AmountChanged(1.0))).called(2);
    });

    testWidgets('handles decimals correctly', (tester) async {
       when(() => mockBloc.state).thenReturn(AddExpenseWizardState(currentUserId: 'u1', transactionId: 't1', expenseDate: tDate));

       await tester.pumpWidget(createWidgetUnderTest());

       await tester.tap(find.text('.'));
       await tester.pump();
       expect(find.text('0.'), findsOneWidget);

       await tester.tap(find.text('5'));
       await tester.pump();
       expect(find.text('0.5'), findsOneWidget);
       verify(() => mockBloc.add(const AmountChanged(0.5))).called(1);
    });
  });
}
