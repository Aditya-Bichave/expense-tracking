import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/add_expense/domain/models/split_model.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/features/add_expense/presentation/widgets/split_screen.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Correct path: 4 levels up to test/ from test/features/add_expense/presentation/widgets/
import '../../../../helpers/pump_app.dart';

class MockAddExpenseWizardBloc
    extends MockBloc<AddExpenseWizardEvent, AddExpenseWizardState>
    implements AddExpenseWizardBloc {}

void main() {
  late MockAddExpenseWizardBloc mockBloc;

  final tMember1 = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'user1',
    role: GroupRole.member,
    joinedAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2023, 1, 1),
  );
  final tMember2 = GroupMember(
    id: 'm2',
    groupId: 'g1',
    userId: 'user2',
    role: GroupRole.member,
    joinedAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2023, 1, 1),
  );

  final tInitialState = AddExpenseWizardState(
    amountTotal: 100,
    currency: r'$',
    splitMode: SplitMode.equal,
    groupMembers: [tMember1, tMember2],
    splits: [
      SplitModel(
        userId: 'user1',
        shareType: SplitType.EQUAL,
        shareValue: 1,
        computedAmount: 50,
      ),
      SplitModel(
        userId: 'user2',
        shareType: SplitType.EQUAL,
        shareValue: 1,
        computedAmount: 50,
      ),
    ],
    currentUserId: 'user1',
    expenseDate: DateTime(2023, 1, 1),
    transactionId: 't1',
  );

  setUp(() {
    mockBloc = MockAddExpenseWizardBloc();
    when(() => mockBloc.state).thenReturn(tInitialState);
  });

  Widget buildTestWidget({required VoidCallback onBack}) {
    return BlocProvider<AddExpenseWizardBloc>.value(
      value: mockBloc,
      child: MaterialApp(home: SplitScreen(onBack: onBack)),
    );
  }

  group('SplitScreen Widget Tests', () {
    testWidgets('renders correct total amount and split mode chips', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(onBack: () {}));

      expect(find.textContaining('Total: \$100.00'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(SplitMode.values.length));
      expect(find.text('Equal Split'), findsOneWidget);
    });

    testWidgets('switching split mode adds SplitModeChanged event', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(onBack: () {}));

      await tester.tap(find.text('Percentages'));
      await tester.pump();

      verify(
        () => mockBloc.add(const SplitModeChanged(SplitMode.percent)),
      ).called(1);
    });

    testWidgets('entering exact value adds SplitValueChanged event', (
      tester,
    ) async {
      when(() => mockBloc.state).thenReturn(
        tInitialState.copyWith(
          splitMode: SplitMode.exact,
          splits: [
            SplitModel(
              userId: 'user1',
              shareType: SplitType.EXACT,
              shareValue: 0,
              computedAmount: 0,
            ),
            SplitModel(
              userId: 'user2',
              shareType: SplitType.EXACT,
              shareValue: 0,
              computedAmount: 0,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildTestWidget(onBack: () {}));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '60');
      await tester.pump();

      verify(
        () => mockBloc.add(const SplitValueChanged('user1', 60.0)),
      ).called(1);
    });

    testWidgets('tapping "Paid by" opens bottom sheet with members', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(onBack: () {}));

      await tester.tap(find.textContaining('Paid by'));
      await tester.pumpAndSettle();

      expect(find.text('Who Paid?'), findsOneWidget);
      expect(find.text('You'), findsOneWidget); // user1 is You
      // Scope to BottomSheet to avoid matching SplitRows in the background
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('user2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'selecting payer in bottom sheet adds SinglePayerSelected event',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(onBack: () {}));

        await tester.tap(find.textContaining('Paid by'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('user2'),
          ),
        );
        await tester.pumpAndSettle();

        verify(
          () => mockBloc.add(const SinglePayerSelected('user2')),
        ).called(1);
        expect(find.text('Who Paid?'), findsNothing);
      },
    );

    testWidgets('SAVE button is disabled if split is invalid', (tester) async {
      when(() => mockBloc.state).thenReturn(
        tInitialState.copyWith(
          isSplitValid: false,
          splitMode: SplitMode.percent,
        ),
      );

      await tester.pumpWidget(buildTestWidget(onBack: () {}));

      final saveButtonFinder = find.ancestor(
        of: find.text('SAVE'),
        matching: find.byType(TextButton),
      );
      final saveButton = tester.widget<TextButton>(saveButtonFinder);
      expect(saveButton.onPressed, isNull);
      expect(find.text('Total percentage must be 100%'), findsOneWidget);
    });

    testWidgets('tapping SAVE adds SubmitExpense event when valid', (
      tester,
    ) async {
      when(
        () => mockBloc.state,
      ).thenReturn(tInitialState.copyWith(isSplitValid: true));

      await tester.pumpWidget(buildTestWidget(onBack: () {}));

      await tester.tap(find.text('SAVE'));
      await tester.pump();

      verify(() => mockBloc.add(const SubmitExpense())).called(1);
    });

    testWidgets('tapping back button calls onBack callback', (tester) async {
      bool backCalled = false;
      await tester.pumpWidget(buildTestWidget(onBack: () => backCalled = true));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backCalled, isTrue);
    });

    testWidgets('shows snackbar on successful submission', (tester) async {
      final states = StreamController<AddExpenseWizardState>();
      whenListen(mockBloc, states.stream);

      await tester.pumpWidget(buildTestWidget(onBack: () {}));

      states.add(tInitialState.copyWith(status: FormStatus.success));
      await tester.pump(); // Trigger listener
      await tester.pump(const Duration(milliseconds: 100)); // Animation

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Expense added securely.'), findsOneWidget);
      await states.close();
    });

    group('AddExpenseWizardState coverage', () {
      test('supports value equality', () {
        final state = AddExpenseWizardState(
          transactionId: '1',
          expenseDate: DateTime(2023),
        );
        expect(
          state,
          equals(
            AddExpenseWizardState(
              transactionId: '1',
              expenseDate: DateTime(2023),
            ),
          ),
        );
      });
    });
  });
}
