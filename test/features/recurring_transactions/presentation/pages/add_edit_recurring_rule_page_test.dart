import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/pages/add_edit_recurring_rule_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockAddEditRecurringRuleBloc
    extends MockBloc<AddEditRecurringRuleEvent, AddEditRecurringRuleState>
    implements AddEditRecurringRuleBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class _FakeAddEditRecurringRuleEvent extends Fake
    implements AddEditRecurringRuleEvent {}

void main() {
  late MockAddEditRecurringRuleBloc ruleBloc;
  late MockCategoryManagementBloc categoryBloc;

  // Pinned so nothing in the widget tree depends on wall-clock time.
  final fixedStart = DateTime(2024, 3, 15, 9, 30);

  AddEditRecurringRuleState stateWith({
    String description = '',
    double amount = 0,
    TransactionType transactionType = TransactionType.expense,
    Category? selectedCategory,
    Frequency frequency = Frequency.monthly,
    int interval = 1,
    TimeOfDay? startTime,
    int? dayOfWeek,
    int? dayOfMonth,
    EndConditionType endConditionType = EndConditionType.never,
    DateTime? endDate,
    int? totalOccurrences,
    FormStatus status = FormStatus.initial,
    String? errorMessage,
    bool isEditMode = false,
  }) {
    return AddEditRecurringRuleState(
      description: description,
      amount: amount,
      transactionType: transactionType,
      selectedCategory: selectedCategory,
      frequency: frequency,
      interval: interval,
      startDate: fixedStart,
      startTime: startTime,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      endConditionType: endConditionType,
      endDate: endDate,
      totalOccurrences: totalOccurrences,
      status: status,
      errorMessage: errorMessage,
      isEditMode: isEditMode,
    );
  }

  setUpAll(() {
    registerFallbackValue(_FakeAddEditRecurringRuleEvent());
  });

  setUp(() async {
    await sl.reset();
    ruleBloc = MockAddEditRecurringRuleBloc();
    categoryBloc = MockCategoryManagementBloc();

    when(() => categoryBloc.state).thenReturn(const CategoryManagementState());
    when(() => ruleBloc.state).thenReturn(stateWith());

    sl.registerFactory<AddEditRecurringRuleBloc>(() => ruleBloc);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    RecurringRule? initialRule,
    bool settle = true,
  }) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: settle,
      accountListState: const AccountListLoaded(accounts: []),
      settingsState: const SettingsState(),
      widget: AddEditRecurringRulePage(initialRule: initialRule),
      blocProviders: [
        BlocProvider<CategoryManagementBloc>.value(value: categoryBloc),
      ],
    );
  }

  group('AddEditRecurringRulePage shell', () {
    testWidgets('resolves the bloc from the service locator and renders', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byType(AddEditRecurringRuleView), findsOneWidget);
      expect(find.text('Add Recurring Rule'), findsOneWidget);
    });

    testWidgets('edit mode seeds the bloc with InitializeForEdit', (
      tester,
    ) async {
      final rule = RecurringRule(
        id: 'r1',
        description: 'Rent',
        amount: 1200,
        transactionType: TransactionType.expense,
        categoryId: 'c1',
        accountId: 'a1',
        frequency: Frequency.monthly,
        interval: 1,
        startDate: fixedStart,
        endConditionType: EndConditionType.never,
        status: RuleStatus.active,
        nextOccurrenceDate: fixedStart,
        occurrencesGenerated: 0,
      );

      await pumpPage(tester, initialRule: rule);

      final captured =
          verify(() => ruleBloc.add(captureAny())).captured.single
              as InitializeForEdit;
      expect(captured.rule.id, 'r1');
      expect(find.text('Edit Recurring Rule'), findsOneWidget);
    });
  });

  group('AddEditRecurringRulePage form fields', () {
    testWidgets('seeds the text controllers from the current bloc state', (
      tester,
    ) async {
      when(() => ruleBloc.state).thenReturn(
        stateWith(description: 'Gym membership', amount: 49.5, interval: 2),
      );

      await pumpPage(tester);

      expect(
        find.widgetWithText(TextFormField, 'Gym membership'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, '49.5'), findsOneWidget);
    });

    testWidgets('leaves the amount field blank when the amount is zero', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(find.widgetWithText(TextFormField, '0.0'), findsNothing);
    });

    testWidgets('typing a description dispatches DescriptionChanged', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Netflix');
      await tester.pump();

      final captured =
          verify(() => ruleBloc.add(captureAny())).captured.last
              as DescriptionChanged;
      expect(captured.description, 'Netflix');
    });

    testWidgets('shows the category placeholder when none is selected', (
      tester,
    ) async {
      await pumpPage(tester);
      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('shows the selected category name when one is set', (
      tester,
    ) async {
      when(() => ruleBloc.state).thenReturn(
        stateWith(
          selectedCategory: const Category(
            id: 'c1',
            name: 'Utilities',
            iconName: 'bolt',
            colorHex: '#FF0000',
            type: CategoryType.expense,
            isCustom: false,
          ),
        ),
      );

      await pumpPage(tester);
      expect(find.text('Utilities'), findsOneWidget);
    });
  });

  group('AddEditRecurringRulePage frequency branches', () {
    testWidgets('daily frequency exposes a start-time tile', (tester) async {
      when(() => ruleBloc.state).thenReturn(
        stateWith(
          frequency: Frequency.daily,
          startTime: const TimeOfDay(hour: 8, minute: 0),
        ),
      );

      await pumpPage(tester);

      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.text('Day of Week'), findsNothing);
      expect(find.text('Day of Month'), findsNothing);
    });

    testWidgets('weekly frequency exposes the day-of-week dropdown', (
      tester,
    ) async {
      when(
        () => ruleBloc.state,
      ).thenReturn(stateWith(frequency: Frequency.weekly, dayOfWeek: 1));

      await pumpPage(tester);

      expect(find.text('Day of Week'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsNothing);
    });

    testWidgets('monthly frequency exposes the day-of-month dropdown', (
      tester,
    ) async {
      when(
        () => ruleBloc.state,
      ).thenReturn(stateWith(frequency: Frequency.monthly, dayOfMonth: 5));

      await pumpPage(tester);

      expect(find.text('Day of Month'), findsOneWidget);
      expect(find.text('Day of Week'), findsNothing);
    });

    testWidgets('yearly frequency shows none of the cadence sub-fields', (
      tester,
    ) async {
      when(
        () => ruleBloc.state,
      ).thenReturn(stateWith(frequency: Frequency.yearly));

      await pumpPage(tester);

      expect(find.text('Day of Week'), findsNothing);
      expect(find.text('Day of Month'), findsNothing);
      expect(find.byIcon(Icons.access_time), findsNothing);
    });
  });

  group('AddEditRecurringRulePage end-condition branches', () {
    testWidgets('never shows neither an end date nor an occurrence count', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byIcon(Icons.calendar_today), findsNothing);
      expect(find.text('Number of Occurrences'), findsNothing);
    });

    testWidgets('onDate shows the end-date placeholder when unset', (
      tester,
    ) async {
      when(
        () => ruleBloc.state,
      ).thenReturn(stateWith(endConditionType: EndConditionType.onDate));

      await pumpPage(tester);

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.text('Select End Date'), findsOneWidget);
    });

    testWidgets('onDate renders the formatted end date when set', (
      tester,
    ) async {
      when(() => ruleBloc.state).thenReturn(
        stateWith(
          endConditionType: EndConditionType.onDate,
          endDate: DateTime(2025, 6, 1),
        ),
      );

      await pumpPage(tester);

      expect(find.text('6/1/2025'), findsOneWidget);
    });

    testWidgets(
      'afterOccurrences shows the occurrence field seeded from state',
      (tester) async {
        when(() => ruleBloc.state).thenReturn(
          stateWith(
            endConditionType: EndConditionType.afterOccurrences,
            totalOccurrences: 12,
          ),
        );

        await pumpPage(tester);

        expect(find.text('Number of Occurrences'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, '12'), findsOneWidget);
      },
    );

    testWidgets('editing the occurrence count dispatches the change event', (
      tester,
    ) async {
      when(() => ruleBloc.state).thenReturn(
        stateWith(
          endConditionType: EndConditionType.afterOccurrences,
          totalOccurrences: 12,
        ),
      );

      await pumpPage(tester);
      await tester.enterText(find.widgetWithText(TextFormField, '12'), '24');
      await tester.pump();

      final captured =
          verify(() => ruleBloc.add(captureAny())).captured.last
              as TotalOccurrencesChanged;
      expect(captured.occurrences, '24');
    });
  });

  group('AddEditRecurringRulePage submission', () {
    testWidgets('save dispatches FormSubmitted with the field contents', (
      tester,
    ) async {
      when(
        () => ruleBloc.state,
      ).thenReturn(stateWith(description: 'Rent', amount: 1200));

      await pumpPage(tester);
      await tester.ensureVisible(find.byType(BridgeElevatedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BridgeElevatedButton));
      await tester.pump();

      final captured =
          verify(() => ruleBloc.add(captureAny())).captured.last
              as FormSubmitted;
      expect(captured.description, 'Rent');
      expect(captured.amount, '1200.0');
    });

    testWidgets('save is disabled and shows a spinner while in progress', (
      tester,
    ) async {
      when(
        () => ruleBloc.state,
      ).thenReturn(stateWith(status: FormStatus.inProgress));

      await pumpPage(tester, settle: false);
      await tester.pump();

      final button = tester.widget<BridgeElevatedButton>(
        find.byType(BridgeElevatedButton),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(BridgeCircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a failure status surfaces the error message in a snackbar', (
      tester,
    ) async {
      whenListen(
        ruleBloc,
        Stream<AddEditRecurringRuleState>.fromIterable([
          stateWith(
            status: FormStatus.failure,
            errorMessage: 'Amount must be positive',
          ),
        ]),
        initialState: stateWith(),
      );

      await pumpPage(tester);

      expect(find.text('Amount must be positive'), findsOneWidget);
    });

    testWidgets('a failure without a message falls back to the generic error', (
      tester,
    ) async {
      whenListen(
        ruleBloc,
        Stream<AddEditRecurringRuleState>.fromIterable([
          stateWith(status: FormStatus.failure),
        ]),
        initialState: stateWith(),
      );

      await pumpPage(tester);

      expect(find.text('An error occurred.'), findsOneWidget);
    });

    testWidgets('the listener re-syncs controllers when the state changes', (
      tester,
    ) async {
      whenListen(
        ruleBloc,
        Stream<AddEditRecurringRuleState>.fromIterable([
          stateWith(description: 'Synced from bloc', amount: 77.25),
        ]),
        initialState: stateWith(),
      );

      await pumpPage(tester);

      expect(
        find.widgetWithText(TextFormField, 'Synced from bloc'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, '77.25'), findsOneWidget);
    });
  });
}
