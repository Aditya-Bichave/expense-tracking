import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/usecases/add_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/archive_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/delete_goal.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';
import 'package:expense_tracker/features/goals/domain/usecases/update_goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/pages/add_edit_goal_page.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goals_sub_tab.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockGetGoalsUseCase extends Mock implements GetGoalsUseCase {}

class MockArchiveGoalUseCase extends Mock implements ArchiveGoalUseCase {}

class MockDeleteGoalUseCase extends Mock implements DeleteGoalUseCase {}

class MockAddGoalUseCase extends Mock implements AddGoalUseCase {}

class MockUpdateGoalUseCase extends Mock implements UpdateGoalUseCase {}

class MockUuid extends Mock implements Uuid {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class _FakeAddGoalParams extends Fake implements AddGoalParams {}

class _FakeUpdateGoalParams extends Fake implements UpdateGoalParams {}

class _FakeArchiveGoalParams extends Fake implements ArchiveGoalParams {}

class _FakeDeleteGoalParams extends Fake implements DeleteGoalParams {}

void main() {
  late MockGetGoalsUseCase getGoals;
  late MockArchiveGoalUseCase archiveGoal;
  late MockDeleteGoalUseCase deleteGoal;
  late MockAddGoalUseCase addGoal;
  late MockUpdateGoalUseCase updateGoal;
  late MockUuid uuid;
  late MockSettingsBloc settingsBloc;
  late StreamController<DataChangedEvent> dataChanges;
  late GoalListBloc goalListBloc;

  final createdAt = DateTime(2024, 1, 1);

  Goal goal({
    String id = 'g1',
    String name = 'New Laptop',
    double target = 1500,
    double saved = 0,
    GoalStatus status = GoalStatus.active,
  }) => Goal(
    id: id,
    name: name,
    targetAmount: target,
    status: status,
    totalSaved: saved,
    createdAt: createdAt,
    iconName: 'savings',
  );

  setUpAll(() {
    registerFallbackValue(_FakeAddGoalParams());
    registerFallbackValue(_FakeUpdateGoalParams());
    registerFallbackValue(_FakeArchiveGoalParams());
    registerFallbackValue(_FakeDeleteGoalParams());
    registerFallbackValue(const NoParams());
  });

  setUp(() async {
    await sl.reset();

    getGoals = MockGetGoalsUseCase();
    archiveGoal = MockArchiveGoalUseCase();
    deleteGoal = MockDeleteGoalUseCase();
    addGoal = MockAddGoalUseCase();
    updateGoal = MockUpdateGoalUseCase();
    uuid = MockUuid();
    settingsBloc = MockSettingsBloc();
    dataChanges = StreamController<DataChangedEvent>.broadcast();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(() => uuid.v4()).thenReturn('generated-goal-id');
    when(() => getGoals(any())).thenAnswer((_) async => const Right(<Goal>[]));

    goalListBloc = GoalListBloc(
      getGoalsUseCase: getGoals,
      archiveGoalUseCase: archiveGoal,
      deleteGoalUseCase: deleteGoal,
      dataChangeStream: dataChanges.stream,
    );

    // The add/edit page resolves its bloc from the locator, with the goal
    // being edited passed as param1.
    sl.registerFactoryParam<AddEditGoalBloc, Goal?, void>(
      (initialGoal, _) => AddEditGoalBloc(
        addGoalUseCase: addGoal,
        updateGoalUseCase: updateGoal,
        uuid: uuid,
        initialGoal: initialGoal,
      ),
    );
  });

  tearDown(() async {
    await goalListBloc.close();
    await dataChanges.close();
    await sl.reset();
  });

  Future<void> pumpFlow(WidgetTester tester, {Goal? editing}) async {
    final router = GoRouter(
      initialLocation: '/goals',
      routes: [
        GoRoute(
          path: '/goals',
          builder: (_, __) => const GoalsSubTab(),
          routes: [
            GoRoute(
              path: 'add',
              name: RouteNames.addGoal,
              builder: (_, state) =>
                  AddEditGoalPage(initialGoal: state.extra as Goal?),
            ),
            GoRoute(
              path: 'edit/:id',
              name: RouteNames.editGoal,
              builder: (_, state) =>
                  AddEditGoalPage(initialGoal: state.extra as Goal?),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GoalListBloc>.value(value: goalListBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    // The initial load is dispatched from outside the widget tree, so it does
    // not run inside the test's fake-async zone. Wait on the bloc reaching a
    // settled state rather than on a duration, so this stays deterministic.
    await tester.runAsync(() async {
      goalListBloc.add(const LoadGoals());
      await goalListBloc.stream.firstWhere(
        (s) => s.status != GoalListStatus.loading,
      );
    });
    await tester.pumpAndSettle();
  }

  /// Pushes [event] through the data-change stream and waits for the list bloc
  /// to finish reacting to it.
  Future<void> emitDataChange(
    WidgetTester tester,
    DataChangedEvent event, {
    bool expectReload = true,
  }) async {
    await tester.runAsync(() async {
      final settled = expectReload
          ? goalListBloc.stream.firstWhere(
              (s) => s.status != GoalListStatus.loading,
            )
          : Future<GoalListState>.value(goalListBloc.state);
      dataChanges.add(event);
      await settled;
    });
    await tester.pumpAndSettle();
  }

  Future<void> fillGoalForm(
    WidgetTester tester, {
    required String name,
    required String amount,
    String? description,
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), name);
    await tester.enterText(fields.at(1), amount);
    if (description != null) {
      await tester.enterText(fields.last, description);
    }
    await tester.pump();
  }

  Future<void> submitGoalForm(WidgetTester tester) async {
    final submit = find.byKey(const ValueKey('button_submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
  }

  group('E2E: create a savings goal', () {
    testWidgets(
      'empty list -> add goal -> use case receives the entered values',
      (tester) async {
        when(() => addGoal(any())).thenAnswer((_) async => Right(goal()));

        await pumpFlow(tester);

        // Starts on the empty state.
        expect(find.text('No Savings Goals Yet'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('button_addFirst')));
        await tester.pumpAndSettle();
        expect(find.text('Add Goal'), findsWidgets);

        await fillGoalForm(
          tester,
          name: 'New Laptop',
          amount: '1500',
          description: 'For work',
        );
        await submitGoalForm(tester);

        final params =
            verify(() => addGoal(captureAny())).captured.single
                as AddGoalParams;
        expect(params.name, 'New Laptop');
        expect(params.targetAmount, 1500);
        expect(params.description, 'For work');
      },
    );

    testWidgets('the new goal appears in the list after a data-change event', (
      tester,
    ) async {
      when(() => addGoal(any())).thenAnswer((_) async => Right(goal()));

      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('button_addFirst')));
      await tester.pumpAndSettle();

      // The repository now has the goal; the list reloads on the event.
      when(() => getGoals(any())).thenAnswer((_) async => Right([goal()]));

      await fillGoalForm(tester, name: 'New Laptop', amount: '1500');
      await submitGoalForm(tester);

      await emitDataChange(
        tester,
        const DataChangedEvent(
          type: DataChangeType.goal,
          reason: DataChangeReason.added,
        ),
      );

      expect(find.byType(GoalCard), findsOneWidget);
      expect(find.text('New Laptop'), findsWidgets);
    });

    testWidgets('an invalid form is rejected before the use case is called', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('button_addFirst')));
      await tester.pumpAndSettle();

      // Submit with an empty name and no amount.
      await submitGoalForm(tester);

      verifyNever(() => addGoal(any()));
      expect(find.text('Please correct the errors.'), findsOneWidget);
    });

    testWidgets('a save failure surfaces the error and stays on the form', (
      tester,
    ) async {
      when(() => addGoal(any())).thenAnswer(
        (_) async => const Left(ValidationFailure('Target must be positive')),
      );

      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('button_addFirst')));
      await tester.pumpAndSettle();
      await fillGoalForm(tester, name: 'Boat', amount: '5000');
      await submitGoalForm(tester);

      expect(find.text('Error: Target must be positive'), findsOneWidget);
      expect(find.byKey(const ValueKey('button_submit')), findsOneWidget);
    });

    testWidgets('the close button abandons the form without saving', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tester.tap(find.byKey(const ValueKey('button_addFirst')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_close')));
      await tester.pumpAndSettle();

      verifyNever(() => addGoal(any()));
      expect(find.text('No Savings Goals Yet'), findsOneWidget);
    });
  });

  group('E2E: edit an existing goal', () {
    testWidgets('editing routes the update through UpdateGoalUseCase', (
      tester,
    ) async {
      final existing = goal(name: 'Old Name', target: 1000);
      when(() => getGoals(any())).thenAnswer((_) async => Right([existing]));
      when(
        () => updateGoal(any()),
      ).thenAnswer((_) async => Right(goal(name: 'New Name')));

      await pumpFlow(tester);
      expect(find.byType(GoalCard), findsOneWidget);

      // Navigate straight into edit mode with the goal as route extra.
      final context = tester.element(find.byType(GoalsSubTab));
      GoRouter.of(context).pushNamed(
        RouteNames.editGoal,
        pathParameters: {'id': existing.id},
        extra: existing,
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Goal'), findsOneWidget);
      expect(find.text('Update Goal'), findsOneWidget);

      await fillGoalForm(tester, name: 'New Name', amount: '2000');
      await submitGoalForm(tester);

      final params =
          verify(() => updateGoal(captureAny())).captured.single
              as UpdateGoalParams;
      expect(params.goal.id, 'g1');
      expect(params.goal.name, 'New Name');
      expect(params.goal.targetAmount, 2000);
      // Editing must not mint a fresh id.
      verifyNever(() => uuid.v4());
    });
  });

  group('E2E: goal list states', () {
    testWidgets('a load failure is surfaced on the list', (tester) async {
      when(() => getGoals(any())).thenAnswer(
        (_) async => const Left(CacheFailure('Goals box unavailable')),
      );

      await pumpFlow(tester);

      expect(find.textContaining('Error loading goals'), findsOneWidget);
    });

    testWidgets('a system reset clears the list and re-reads the source', (
      tester,
    ) async {
      when(() => getGoals(any())).thenAnswer((_) async => Right([goal()]));

      await pumpFlow(tester);
      expect(find.byType(GoalCard), findsOneWidget);

      // A reset wipes local data, so the source now has nothing to return.
      when(
        () => getGoals(any()),
      ).thenAnswer((_) async => const Right(<Goal>[]));

      await tester.runAsync(() async {
        final reloaded = goalListBloc.stream.firstWhere(
          (s) => s.status == GoalListStatus.success && s.goals.isEmpty,
        );
        dataChanges.add(
          const DataChangedEvent(
            type: DataChangeType.system,
            reason: DataChangeReason.reset,
          ),
        );
        await reloaded;
      });
      await tester.pumpAndSettle();

      expect(find.byType(GoalCard), findsNothing);
      expect(find.text('No Savings Goals Yet'), findsOneWidget);
    });

    testWidgets('a contribution event triggers a list reload', (tester) async {
      when(() => getGoals(any())).thenAnswer((_) async => Right([goal()]));

      await pumpFlow(tester);
      clearInteractions(getGoals);

      await emitDataChange(
        tester,
        const DataChangedEvent(
          type: DataChangeType.goalContribution,
          reason: DataChangeReason.added,
        ),
      );

      verify(() => getGoals(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('an unrelated data-change event does not reload the list', (
      tester,
    ) async {
      when(() => getGoals(any())).thenAnswer((_) async => Right([goal()]));

      await pumpFlow(tester);
      clearInteractions(getGoals);

      await emitDataChange(
        tester,
        const DataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.added,
        ),
        expectReload: false,
      );

      verifyNever(() => getGoals(any()));
    });
  });
}
