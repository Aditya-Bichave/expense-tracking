import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/contribution_list/contribution_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetContributionsUseCase extends Mock
    implements GetContributionsForGoalUseCase {}

void main() {
  late MockGetContributionsUseCase mockGetContributionsUseCase;
  late StreamController<DataChangedEvent> dataChangeController;

  setUp(() {
    mockGetContributionsUseCase = MockGetContributionsUseCase();
    dataChangeController = StreamController<DataChangedEvent>.broadcast();
    registerFallbackValue(const GetContributionsParams(goalId: 'g1'));
  });

  tearDown(() async {
    await dataChangeController.close();
  });

  final tContribution = GoalContribution(
    id: 'c1',
    goalId: 'g1',
    amount: 50,
    date: DateTime(2024, 1, 1),
    createdAt: DateTime(2024, 1, 1),
  );

  group('LoadContributions', () {
    blocTest<ContributionListBloc, ContributionListState>(
      'emits [loading, success] when data fetched',
      build: () {
        when(
          () => mockGetContributionsUseCase(any()),
        ).thenAnswer((_) async => Right([tContribution]));
        return ContributionListBloc(
          goalId: 'g1',
          getContributionsUseCase: mockGetContributionsUseCase,
          dataChangeStream: dataChangeController.stream,
        );
      },
      act: (bloc) => bloc.add(const LoadContributions()),
      expect: () => [
        const ContributionListState(status: ContributionListStatus.loading),
        ContributionListState(
          status: ContributionListStatus.success,
          contributions: [tContribution],
        ),
      ],
    );

    blocTest<ContributionListBloc, ContributionListState>(
      'emits [loading, error] when fetch fails',
      build: () {
        when(
          () => mockGetContributionsUseCase(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('oops')));
        return ContributionListBloc(
          goalId: 'g1',
          getContributionsUseCase: mockGetContributionsUseCase,
          dataChangeStream: dataChangeController.stream,
        );
      },
      act: (bloc) => bloc.add(const LoadContributions()),
      expect: () => [
        const ContributionListState(status: ContributionListStatus.loading),
        const ContributionListState(
          status: ContributionListStatus.error,
          errorMessage: 'oops',
        ),
      ],
    );
  });
}
