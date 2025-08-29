import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import '../../../../helpers/pump_app.dart';

class MockGoalListBloc extends MockBloc<GoalListEvent, GoalListState>
    implements GoalListBloc {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGetContributionsUseCase extends Mock
    implements GetContributionsForGoalUseCase {}

class FakeGoalListEvent extends Fake implements GoalListEvent {}

void main() {
  late GoalListBloc mockGoalListBloc;
  late MockGoalRepository mockGoalRepository;
  late MockGetContributionsUseCase mockGetContributionsUseCase;

  final mockGoal = Goal(
    id: '1',
    name: 'Test Goal',
    targetAmount: 1000,
    totalSaved: 500,
    status: GoalStatus.active,
    createdAt: DateTime(2023),
  );

  setUpAll(() {
    registerFallbackValue(const GetContributionsParams(goalId: ''));
    registerFallbackValue(FakeGoalListEvent());
  });

  setUp(() {
    mockGoalListBloc = MockGoalListBloc();
    mockGoalRepository = MockGoalRepository();
    mockGetContributionsUseCase = MockGetContributionsUseCase();
    sl.registerSingleton<GoalRepository>(mockGoalRepository);
    sl.registerSingleton<GetContributionsForGoalUseCase>(
        mockGetContributionsUseCase);
  });

  tearDown(() {
    sl.reset();
  });

  Widget buildTestWidget() {
    return BlocProvider.value(
      value: mockGoalListBloc,
      child: GoalDetailPage(goalId: '1', initialGoal: mockGoal),
    );
  }

  group('GoalDetailPage', () {
    testWidgets('shows loading and then displays details', (tester) async {
      when(() => mockGoalRepository.getGoalById(any()))
          .thenAnswer((_) async => Right(mockGoal));
      when(() => mockGetContributionsUseCase.call(any()))
          .thenAnswer((_) async => const Right([]));

      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('Test Goal'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
    });

    testWidgets('tapping Edit button navigates', (tester) async {
      when(() => mockGoalRepository.getGoalById(any()))
          .thenAnswer((_) async => Right(mockGoal));
      when(() => mockGetContributionsUseCase.call(any()))
          .thenAnswer((_) async => const Right([]));

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => buildTestWidget(),
            routes: [
              GoRoute(
                path: 'edit/:id',
                name: RouteNames.editGoal,
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      );

      await pumpWidgetWithProviders(
        tester: tester,
        router: router,
        widget: const SizedBox.shrink(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_edit')));
    });

    testWidgets('tapping Archive shows dialog and dispatches event',
        (tester) async {
      when(() => mockGoalRepository.getGoalById(any()))
          .thenAnswer((_) async => Right(mockGoal));
      when(() => mockGetContributionsUseCase.call(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => mockGoalListBloc.add(any())).thenAnswer((_) {});

      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_archive')));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Archive'), findsOneWidget);

      await tester.tap(find.text('Archive'));
      await tester.pump();

      verify(() => mockGoalListBloc.add(const ArchiveGoal(goalId: '1')))
          .called(1);
    });
  });
}
