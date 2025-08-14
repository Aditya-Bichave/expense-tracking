import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/main.dart';

part 'contribution_list_event.dart';
part 'contribution_list_state.dart';

class ContributionListBloc
    extends Bloc<ContributionListEvent, ContributionListState> {
  final GetContributionsForGoalUseCase _getContributionsUseCase;
  final String goalId;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  ContributionListBloc({
    required this.goalId,
    required GetContributionsForGoalUseCase getContributionsUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  }) : _getContributionsUseCase = getContributionsUseCase,
       super(const ContributionListState()) {
    on<LoadContributions>(_onLoadContributions);
    on<_ContributionsDataChanged>(_onDataChanged);

    _dataChangeSubscription = dataChangeStream.listen((event) {
      if (event.type == DataChangeType.goalContribution) {
        add(const _ContributionsDataChanged());
      }
    });

    log.info('[ContributionListBloc] Initialized for goal $goalId');
  }

  Future<void> _onLoadContributions(
    LoadContributions event,
    Emitter<ContributionListState> emit,
  ) async {
    if (state.status == ContributionListStatus.loading && !event.forceReload) {
      log.fine(
        '[ContributionListBloc] LoadContributions ignored, already loading.',
      );
      return;
    }

    emit(
      state.copyWith(status: ContributionListStatus.loading, clearError: true),
    );
    final result = await _getContributionsUseCase(
      GetContributionsParams(goalId: goalId),
    );
    result.fold(
      (failure) {
        log.warning(
          '[ContributionListBloc] Failed to load contributions: ${failure.message}',
        );
        emit(
          state.copyWith(
            status: ContributionListStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (contributions) {
        log.info(
          '[ContributionListBloc] Loaded ${contributions.length} contributions for goal $goalId.',
        );
        emit(
          state.copyWith(
            status: ContributionListStatus.success,
            contributions: contributions,
          ),
        );
      },
    );
  }

  void _onDataChanged(
    _ContributionsDataChanged event,
    Emitter<ContributionListState> emit,
  ) {
    if (state.status != ContributionListStatus.loading) {
      add(const LoadContributions(forceReload: true));
    }
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    return super.close();
  }
}
