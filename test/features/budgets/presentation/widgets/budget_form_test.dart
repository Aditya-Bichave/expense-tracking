import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockOnSubmit extends Mock {
  void call(
    String name,
    BudgetType type,
    double targetAmount,
    BudgetPeriodType period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    String? notes,
  );
}

void main() {
  late MockOnSubmit mockOnSubmit;

  setUp(() {
    mockOnSubmit = MockOnSubmit();
    when(
      () => mockOnSubmit.call(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) {});
  });

  final mockBudget = Budget(
    id: '1',
    name: 'Initial Budget',
    targetAmount: 500,
    type: BudgetType.overall,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: DateTime(2023),
  );

  group('BudgetForm', () {
    testWidgets('initializes correctly in "add" mode', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetForm(
          onSubmit: mockOnSubmit.call,
          availableCategories: const [],
        ),
      );
      expect(find.text('Add Budget'), findsOneWidget);
    });

    testWidgets('initializes correctly in "edit" mode', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetForm(
          initialBudget: mockBudget,
          onSubmit: mockOnSubmit.call,
          availableCategories: const [],
        ),
      );
      expect(find.text('Update Budget'), findsOneWidget);
      expect(find.text('Initial Budget'), findsOneWidget);
      expect(find.text('500.00'), findsOneWidget);
    });

    testWidgets('onSubmit is called with correct data when form is valid', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetForm(
          onSubmit: mockOnSubmit.call,
          availableCategories: const [],
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Budget Name'),
        'Test Budget',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Target Amount'),
        '1000',
      );

      await tester.tap(find.byKey(const ValueKey('button_submit')));
      await tester.pump();

      verify(
        () => mockOnSubmit.call(
          'Test Budget',
          BudgetType.overall,
          1000.0,
          BudgetPeriodType.recurringMonthly,
          null,
          null,
          null,
          null,
        ),
      ).called(1);
    });

    testWidgets('shows error if category is required but not selected', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: BudgetForm(
          onSubmit: mockOnSubmit.call,
          availableCategories: const [],
        ),
      );

      // Change type to category specific
      await tester.tap(find.text('Overall Spending'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Category-Specific').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_submit')));
      await tester.pump();

      expect(find.text('Please select at least one category.'), findsOneWidget);
      verifyNever(
        () => mockOnSubmit.call(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      );
    }, skip: true);
  });
}
