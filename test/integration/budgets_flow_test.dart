import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/add_edit_budget_page.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_form.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockAddBudgetUseCase extends Mock implements AddBudgetUseCase {}

class MockUpdateBudgetUseCase extends Mock implements UpdateBudgetUseCase {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockUuid extends Mock implements Uuid {}

class _FakeAddBudgetParams extends Fake implements AddBudgetParams {}

class _FakeUpdateBudgetParams extends Fake implements UpdateBudgetParams {}

void main() {
  late MockBudgetListBloc budgetListBloc;
  late MockSettingsBloc settingsBloc;
  late MockAddBudgetUseCase addBudget;
  late MockUpdateBudgetUseCase updateBudget;
  late MockCategoryRepository categoryRepository;

  final createdAt = DateTime(2024, 1, 1);

  Budget budget({
    String id = 'b1',
    String name = 'Groceries',
    double target = 500,
  }) => Budget(
    id: id,
    name: name,
    type: BudgetType.overall,
    targetAmount: target,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: createdAt,
  );

  setUpAll(() {
    registerFallbackValue(_FakeAddBudgetParams());
    registerFallbackValue(_FakeUpdateBudgetParams());
    registerFallbackValue(const LoadBudgets());
    registerFallbackValue(CategoryType.expense);
  });

  setUp(() async {
    await sl.reset();
    budgetListBloc = MockBudgetListBloc();
    settingsBloc = MockSettingsBloc();
    addBudget = MockAddBudgetUseCase();
    updateBudget = MockUpdateBudgetUseCase();
    categoryRepository = MockCategoryRepository();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(
      () => budgetListBloc.state,
    ).thenReturn(const BudgetListState(status: BudgetListStatus.success));
    // The add/edit bloc loads the selectable expense categories on init.
    when(
      () => categoryRepository.getSpecificCategories(
        type: any(named: 'type'),
        includeCustom: any(named: 'includeCustom'),
      ),
    ).thenAnswer((_) async => const Right(<Category>[]));

    // AddEditBudgetBloc pulls Uuid straight out of the locator when saving.
    final uuid = MockUuid();
    when(() => uuid.v4()).thenReturn('generated-budget-id');
    sl.registerLazySingleton<Uuid>(() => uuid);

    sl.registerFactoryParam<AddEditBudgetBloc, Budget?, void>(
      (initialBudget, _) => AddEditBudgetBloc(
        addBudgetUseCase: addBudget,
        updateBudgetUseCase: updateBudget,
        categoryRepository: categoryRepository,
        initialBudget: initialBudget,
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpFlow(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/plan',
      routes: [
        GoRoute(
          path: '/plan',
          builder: (_, __) => const BudgetsSubTab(),
          routes: [
            GoRoute(
              path: 'add',
              name: RouteNames.addBudget,
              builder: (_, state) =>
                  AddEditBudgetPage(initialBudget: state.extra as Budget?),
            ),
            GoRoute(
              path: 'edit/:id',
              name: RouteNames.editBudget,
              builder: (_, state) =>
                  AddEditBudgetPage(initialBudget: state.extra as Budget?),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<BudgetListBloc>.value(value: budgetListBloc),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillBudgetForm(
    WidgetTester tester, {
    required String name,
    required String amount,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), amount);
    await tester.pump();
  }

  Future<void> submitBudgetForm(WidgetTester tester) async {
    final submit = find.byKey(const ValueKey('button_submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  group('E2E: create a budget', () {
    testWidgets('empty list -> add -> AddBudgetUseCase receives the values', (
      tester,
    ) async {
      when(() => addBudget(any())).thenAnswer((_) async => Right(budget()));

      await pumpFlow(tester);
      expect(find.text('No Budgets Created Yet'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('button_budgetList_addFirst')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BudgetForm), findsOneWidget);

      await fillBudgetForm(tester, name: 'Groceries', amount: '500');
      await submitBudgetForm(tester);

      final params =
          verify(() => addBudget(captureAny())).captured.single
              as AddBudgetParams;
      expect(params.name, 'Groceries');
      expect(params.targetAmount, 500);
      expect(params.type, BudgetType.overall);
      // An overall budget carries no category filter.
      expect(params.categoryIds, isNull);
    });

    testWidgets('the FAB opens the same form', (tester) async {
      await pumpFlow(tester);

      await tester.tap(find.byKey(const ValueKey('fab_budgetList_add')));
      await tester.pumpAndSettle();

      expect(find.byType(BudgetForm), findsOneWidget);
      expect(find.text('Add Budget'), findsWidgets);
    });

    testWidgets('a successful save returns to the budget list', (tester) async {
      when(() => addBudget(any())).thenAnswer((_) async => Right(budget()));

      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('fab_budgetList_add')));
      await tester.pumpAndSettle();
      await fillBudgetForm(tester, name: 'Groceries', amount: '500');
      await submitBudgetForm(tester);

      expect(find.byType(BudgetForm), findsNothing);
      expect(find.text('Budget added successfully!'), findsOneWidget);
    });

    testWidgets('an invalid form never reaches the use case', (tester) async {
      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('fab_budgetList_add')));
      await tester.pumpAndSettle();

      await submitBudgetForm(tester);

      verifyNever(() => addBudget(any()));
      expect(find.text('Please correct the errors.'), findsOneWidget);
    });

    testWidgets('a save failure surfaces the error and keeps the form', (
      tester,
    ) async {
      when(() => addBudget(any())).thenAnswer(
        (_) async => const Left(ValidationFailure('Target must be positive')),
      );

      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('fab_budgetList_add')));
      await tester.pumpAndSettle();
      await fillBudgetForm(tester, name: 'Groceries', amount: '500');
      await submitBudgetForm(tester);

      expect(find.text('Error: Target must be positive'), findsOneWidget);
      expect(find.byType(BudgetForm), findsOneWidget);
    });

    testWidgets('closing the form abandons the budget', (tester) async {
      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('fab_budgetList_add')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_close')));
      await tester.pumpAndSettle();

      verifyNever(() => addBudget(any()));
      expect(find.byType(BudgetForm), findsNothing);
    });
  });

  group('E2E: edit a budget', () {
    testWidgets('editing routes through UpdateBudgetUseCase with the same id', (
      tester,
    ) async {
      final existing = budget(name: 'Old', target: 100);
      when(
        () => updateBudget(any()),
      ).thenAnswer((_) async => Right(budget(name: 'New')));

      await pumpFlow(tester);

      final context = tester.element(find.byType(BudgetsSubTab));
      GoRouter.of(context).pushNamed(
        RouteNames.editBudget,
        pathParameters: {'id': existing.id},
        extra: existing,
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Budget'), findsOneWidget);

      await fillBudgetForm(tester, name: 'New', amount: '750');
      await submitBudgetForm(tester);

      final params =
          verify(() => updateBudget(captureAny())).captured.single
              as UpdateBudgetParams;
      expect(params.budget.id, 'b1');
      expect(params.budget.name, 'New');
      expect(params.budget.targetAmount, 750);
      verifyNever(() => addBudget(any()));
    });
  });

  group('E2E: budget list states', () {
    testWidgets('an error state is surfaced on the list', (tester) async {
      when(() => budgetListBloc.state).thenReturn(
        const BudgetListState(
          status: BudgetListStatus.error,
          errorMessage: 'Budgets box unavailable',
        ),
      );

      await pumpFlow(tester);

      expect(
        find.text('Error loading budgets: Budgets box unavailable'),
        findsOneWidget,
      );
    });
  });
}
