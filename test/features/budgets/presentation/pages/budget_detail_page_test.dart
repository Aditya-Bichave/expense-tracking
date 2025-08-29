import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/pump_app.dart';

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

void main() {
  late BudgetListBloc mockBudgetListBloc;
  late MockGetTransactionsUseCase mockGetTransactionsUseCase;
  late MockGoRouter mockGoRouter;
  late CategoryManagementBloc mockCategoryManagementBloc;

  final mockBudget = Budget(
    id: '1',
    name: 'Groceries',
    type: BudgetType.overall,
    targetAmount: 500,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: DateTime(2024),
  );
  final mockBudgetWithStatus = BudgetWithStatus(
    budget: mockBudget,
    amountSpent: 250,
    amountRemaining: 250,
    percentageUsed: 0.5,
    health: BudgetHealth.thriving,
    statusColor: Colors.green,
  );

  setUpAll(() {
    registerFallbackValue(const GetTransactionsParams());
  });

  setUp(() {
    mockBudgetListBloc = MockBudgetListBloc();
    mockGetTransactionsUseCase = MockGetTransactionsUseCase();
    mockGoRouter = MockGoRouter();
    mockCategoryManagementBloc = MockCategoryManagementBloc();
    when(() => mockCategoryManagementBloc.state)
        .thenReturn(const CategoryManagementState());
    sl.registerSingleton<GetTransactionsUseCase>(mockGetTransactionsUseCase);
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<CategoryManagementBloc>.value(
            value: mockCategoryManagementBloc),
      ],
      child: const BudgetDetailPage(budgetId: '1'),
    );
  }

  group('BudgetDetailPage', () {
    testWidgets('shows loading indicator and then displays details',
        (tester) async {
      when(() => mockBudgetListBloc.state).thenReturn(
        BudgetListState(
          status: BudgetListStatus.success,
          budgetsWithStatus: [mockBudgetWithStatus],
        ),
      );
      when(() => mockGetTransactionsUseCase.call(any()))
          .thenAnswer((_) async => const Right([]));

      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(),
        settle: false,
      );

      // Starts in loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After loading, displays details
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.textContaining('Spent:'), findsOneWidget);
      expect(find.textContaining('Target:'), findsOneWidget);
    });

    testWidgets('tapping Edit button navigates to edit page', (tester) async {
      when(() => mockBudgetListBloc.state).thenReturn(
        BudgetListState(
          status: BudgetListStatus.success,
          budgetsWithStatus: [mockBudgetWithStatus],
        ),
      );
      when(() => mockGetTransactionsUseCase.call(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockGoRouter.pushNamed(RouteNames.editBudget,
          pathParameters: any(named: 'pathParameters'),
          extra: any(named: 'extra'))).thenAnswer((_) async => {});

      await pumpWidgetWithProviders(
          tester: tester, router: mockGoRouter, widget: buildTestWidget());
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey('button_edit'), skipOffstage: false));

      verify(() => mockGoRouter.pushNamed(
            RouteNames.editBudget,
            pathParameters: {'id': '1'},
            extra: mockBudget,
          )).called(1);
    }, skip: true);

    testWidgets('tapping Delete button shows dialog and dispatches event',
        (tester) async {
      when(() => mockBudgetListBloc.state).thenReturn(
        BudgetListState(
          status: BudgetListStatus.success,
          budgetsWithStatus: [mockBudgetWithStatus],
        ),
      );
      when(() => mockGetTransactionsUseCase.call(any()))
          .thenAnswer((_) async => const Right([]));

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_delete')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pump();

      verify(() => mockBudgetListBloc.add(const DeleteBudget(budgetId: '1')))
          .called(1);
    });
  });
}
