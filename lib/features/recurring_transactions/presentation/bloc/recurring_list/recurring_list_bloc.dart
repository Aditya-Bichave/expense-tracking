import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/delete_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rules.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/pause_resume_recurring_rule.dart';

part 'recurring_list_event.dart';
part 'recurring_list_state.dart';

class RecurringListBloc extends Bloc<RecurringListEvent, RecurringListState> {
  final GetRecurringRules getRecurringRules;
  final PauseResumeRecurringRule pauseResumeRecurringRule;
  final DeleteRecurringRule deleteRecurringRule;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  RecurringListBloc({
    required this.getRecurringRules,
    required this.pauseResumeRecurringRule,
    required this.deleteRecurringRule,
    required Stream<DataChangedEvent> dataChangedEventStream,
  }) : super(RecurringListInitial()) {
    on<LoadRecurringRules>(_onLoadRecurringRules, transformer: restartable());
    on<PauseResumeRule>(_onPauseResumeRule);
    on<DeleteRule>(_onDeleteRule);

    _dataChangeSubscription = dataChangedEventStream.listen((event) {
      if (event.type == DataChangeType.recurringRule) {
        add(LoadRecurringRules());
      }
    });
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    return super.close();
  }

  Future<void> _onLoadRecurringRules(
    LoadRecurringRules event,
    Emitter<RecurringListState> emit,
  ) async {
    emit(RecurringListLoading());
    final failureOrRules = await getRecurringRules(NoParams());
    failureOrRules.fold(
      (failure) => emit(RecurringListError(failure.message)),
      (rules) => emit(RecurringListLoaded(rules)),
    );
  }

  Future<void> _onPauseResumeRule(
    PauseResumeRule event,
    Emitter<RecurringListState> emit,
  ) async {
    final failureOrSuccess = await pauseResumeRecurringRule(event.ruleId);
    failureOrSuccess.fold(
      (failure) => emit(RecurringListError(failure.message)),
      (_) => publishDataChangedEvent(
        type: DataChangeType.recurringRule,
        reason: DataChangeReason.updated,
      ),
    );
  }

  Future<void> _onDeleteRule(
    DeleteRule event,
    Emitter<RecurringListState> emit,
  ) async {
    final failureOrSuccess = await deleteRecurringRule(event.ruleId);
    failureOrSuccess.fold(
      (failure) => emit(RecurringListError(failure.message)),
      (_) => publishDataChangedEvent(
        type: DataChangeType.recurringRule,
        reason: DataChangeReason.deleted,
      ),
    );
  }
}
