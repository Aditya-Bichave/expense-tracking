import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/split_screen.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/models/payer_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

class MockAddExpenseWizardBloc
    extends MockBloc<AddExpenseWizardEvent, AddExpenseWizardState>
    implements AddExpenseWizardBloc {}

void main() {
  late MockAddExpenseWizardBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const WizardStarted());
    registerFallbackValue(const SplitModeChanged(SplitMode.equal));
  });

  setUp(() {
    mockBloc = MockAddExpenseWizardBloc();
    when(() => mockBloc.state).thenReturn(
      AddExpenseWizardState(
        amountTotal: 100.0,
        currency: '\$',
        expenseDate: DateTime.now(),
        transactionId: 'test-tx-id',
        currentUserId: 'user1',
        groupMembers: [
          GroupMember(
            id: '1',
            groupId: 'g1',
            userId: 'user1',
            role: GroupRole.member,
            joinedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        payers: [PayerModel(userId: 'user1', amountPaid: 100.0)],
      ),
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AddExpenseWizardBloc>.value(
        value: mockBloc,
        child: SplitScreen(onBack: () {}),
      ),
    );
  }

  testWidgets('SplitScreen renders correctly', (tester) async {
    // Set a wide enough screen to prevent truncation of segmented control text
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Split Expense'), findsOneWidget);
    expect(find.text('Total: \$100.00'), findsOneWidget);
    expect(find.text('Paid by You'), findsOneWidget);
    // Correct display name "Equal Split"
    expect(find.text('Equal Split'), findsOneWidget);
  });

  testWidgets('SplitScreen changing split mode updates bloc', (tester) async {
    // Set a wide enough screen
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Correct display name "Exact Amounts"
    await tester.tap(find.text('Exact Amounts'));
    await tester.pump();

    verify(
      () => mockBloc.add(const SplitModeChanged(SplitMode.exact)),
    ).called(1);
  });
}
