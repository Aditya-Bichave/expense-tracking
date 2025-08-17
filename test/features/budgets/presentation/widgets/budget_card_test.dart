import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_card.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockCategoryManagementBloc extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockOnTap extends Mock {
  void call();
}

void main() {
  late CategoryManagementBloc mockCategoryBloc;
  final mockBudgetStatus = BudgetWithStatus(
    budget: Budget(id: '1', name: 'Groceries', targetAmount: 500, type: BudgetType.overall, period: BudgetPeriodType.recurringMonthly),
    amountSpent: 250,
    percentageUsed: 0.5,
    health: BudgetHealth.healthy,
    statusColor: Colors.green,
  );

  setUp(() {
    mockCategoryBloc = MockCategoryManagementBloc();
    when(() => mockCategoryBloc.state).thenReturn(const CategoryManagementState());
  });

  Widget buildTestWidget({required BudgetWithStatus budgetStatus, VoidCallback? onTap}) {
    return BlocProvider.value(
      value: mockCategoryBloc,
      child: BudgetCard(budgetStatus: budgetStatus, onTap: onTap),
    );
  }

  group('BudgetCard', () {
    testWidgets('renders budget name, period, and amounts', (tester) async {
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget(budgetStatus: mockBudgetStatus));

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.textContaining('Spent:'), findsOneWidget);
      expect(find.textContaining('Target:'), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      final mockOnTap = MockOnTap();
      when(() => mockOnTap.call()).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(budgetStatus: mockBudgetStatus, onTap: mockOnTap.call),
      );

      await tester.tap(find.byType(InkWell));
      verify(() => mockOnTap.call()).called(1);
    });
  });
}
