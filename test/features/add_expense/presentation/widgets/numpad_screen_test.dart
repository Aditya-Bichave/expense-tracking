import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/numpad_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
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

    // Check key '0' specifically by finding InkWell with '0'
    // Or simpler: just ensure at least one '0' is visible.
    // The previous error was "found too many".
    expect(find.text('0'), findsAtLeastNWidgets(1));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('.'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
  });

  testWidgets('NumpadScreen updates amount on key press', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap the '1' KEY.
    // Since '1' is only on the keypad (display is '0'), find.text('1') is unique.
    await tester.tap(find.text('1'));
    await tester.pump();

    verify(() => mockBloc.add(const AmountChanged(1.0))).called(1);
  });

  testWidgets('NumpadScreen handles backspace', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Enter '1' then delete it
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    // Verify AmountChanged called twice (once for 1, once for 0)
    verify(() => mockBloc.add(any(that: isA<AmountChanged>()))).called(2);
  });
}
