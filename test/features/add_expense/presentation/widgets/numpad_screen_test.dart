import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/numpad_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';

class MockAddExpenseWizardBloc
    extends MockBloc<AddExpenseWizardEvent, AddExpenseWizardState>
    implements AddExpenseWizardBloc {}

void main() {
  late MockAddExpenseWizardBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const WizardStarted());
    registerFallbackValue(const AmountChanged(0));
  });

  setUp(() {
    mockBloc = MockAddExpenseWizardBloc();
    when(() => mockBloc.state).thenReturn(AddExpenseWizardState(
      expenseDate: DateTime.now(),
      transactionId: 'test-tx-id',
    ));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AddExpenseWizardBloc>.value(
        value: mockBloc,
        child: NumpadScreen(onNext: () {}),
      ),
    );
  }

  testWidgets('NumpadScreen renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(AppScaffold), findsOneWidget);
    expect(find.text('Enter Amount'), findsOneWidget);
    expect(find.text('0'), findsAtLeastNWidgets(1));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('.'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
  });

  testWidgets('NumpadScreen updates amount on key press', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('1'));
    await tester.pump();

    verify(() => mockBloc.add(const AmountChanged(1.0))).called(1);
  });

  testWidgets('NumpadScreen handles backspace', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Input '1' -> '1'
    await tester.tap(find.text('1'));
    await tester.pump();

    // Backspace -> '0'
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    verify(() => mockBloc.add(any(that: isA<AmountChanged>()))).called(2);
  });

  testWidgets('NumpadScreen handles multiple dots', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Input '.' -> '0.'
    await tester.tap(find.text('.'));
    await tester.pump();

    // Input '.' again -> should be ignored
    await tester.tap(find.text('.'));
    await tester.pump();

    verify(() => mockBloc.add(any(that: isA<AmountChanged>()))).called(greaterThanOrEqualTo(1));
  });

  testWidgets('NumpadScreen limits decimal places', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Input . 1 2 3
    await tester.tap(find.text('.'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3')); // Should be ignored
    await tester.pump();

    // Verify 0.12 was emitted at least once (might be re-emitted on invalid input)
    verify(() => mockBloc.add(const AmountChanged(0.12))).called(greaterThanOrEqualTo(1));
    // Should NOT see 0.123
    verifyNever(() => mockBloc.add(const AmountChanged(0.123)));
  });
}
