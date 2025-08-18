import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/add_edit_budget_page.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockAddEditBudgetBloc
    extends MockBloc<AddEditBudgetEvent, AddEditBudgetState>
    implements AddEditBudgetBloc {}

void main() {
  late AddEditBudgetBloc mockBloc;

  setUp(() {
    mockBloc = MockAddEditBudgetBloc();
    sl.registerFactoryParam<AddEditBudgetBloc, Budget?, void>(
        (param1, _) => mockBloc);
  });

  tearDown(() {
    sl.reset();
  });

  final mockBudget = Budget(
    id: '1',
    name: 'Test',
    type: BudgetType.overall,
    targetAmount: 100,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: DateTime(2024),
  );

  group('AddEditBudgetPage', () {
    testWidgets('renders correct AppBar title for "Add" mode', (tester) async {
      when(() => mockBloc.state).thenReturn(const AddEditBudgetState());
      await pumpWidgetWithProviders(
          tester: tester, widget: const AddEditBudgetPage());
      expect(find.text('Add Budget'), findsOneWidget);
    });

    testWidgets('renders correct AppBar title for "Edit" mode', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(AddEditBudgetState(initialBudget: mockBudget));
      await pumpWidgetWithProviders(
          tester: tester, widget: AddEditBudgetPage(initialBudget: mockBudget));
      expect(find.text('Edit Budget'), findsOneWidget);
    });

    testWidgets('renders BudgetForm when categories are loaded',
        (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const AddEditBudgetState(availableCategories: []));
      await pumpWidgetWithProviders(
          tester: tester, widget: const AddEditBudgetPage());
      expect(find.byType(BudgetForm), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading categories',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
          const AddEditBudgetState(status: AddEditBudgetStatus.loading));
      await pumpWidgetWithProviders(
          tester: tester, widget: const AddEditBudgetPage());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success SnackBar when state is success', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AddEditBudgetState(status: AddEditBudgetStatus.success)]),
        initialState: const AddEditBudgetState(),
      );
      await pumpWidgetWithProviders(
          tester: tester, widget: const AddEditBudgetPage());
      await tester.pump();
      expect(find.text('Budget added successfully!'), findsOneWidget);
    });
  });
}
