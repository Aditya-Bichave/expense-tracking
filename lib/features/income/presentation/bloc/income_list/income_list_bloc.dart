import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';

part 'income_list_event.dart';
part 'income_list_state.dart';

class IncomeListBloc extends Bloc<IncomeListEvent, IncomeListState> {
  final GetIncomesUseCase _getIncomesUseCase;
  final DeleteIncomeUseCase _deleteIncomeUseCase;

  // Store current filters
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentCategory;
  String? _currentAccountId;

  IncomeListBloc({
    required GetIncomesUseCase getIncomesUseCase,
    required DeleteIncomeUseCase deleteIncomeUseCase,
  })  : _getIncomesUseCase = getIncomesUseCase,
        _deleteIncomeUseCase = deleteIncomeUseCase,
        super(IncomeListInitial()) {
    on<LoadIncomes>(_onLoadIncomes);
    on<FilterIncomes>(_onFilterIncomes);
    on<DeleteIncomeRequested>(_onDeleteIncomeRequested);
    debugPrint("[IncomeListBloc] Initialized.");
  }

  Future<void> _onLoadIncomes(
      LoadIncomes event, Emitter<IncomeListState> emit) async {
    debugPrint("[IncomeListBloc] Received LoadIncomes event.");
    if (state is! IncomeListLoaded) {
      debugPrint(
          "[IncomeListBloc] Current state is not Loaded. Emitting IncomeListLoading.");
      emit(IncomeListLoading());
    } else {
      debugPrint(
          "[IncomeListBloc] Current state is Loaded. Refreshing data without emitting Loading.");
    }

    final params = GetIncomesParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      category: _currentCategory,
      accountId: _currentAccountId,
    );
    debugPrint(
        "[IncomeListBloc] Calling GetIncomesUseCase with params: AccID=${params.accountId}, Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");

    try {
      final result = await _getIncomesUseCase(params);
      debugPrint(
          "[IncomeListBloc] GetIncomesUseCase returned. Result isLeft: ${result.isLeft()}");

      result.fold(
        (failure) {
          debugPrint(
              "[IncomeListBloc] Emitting IncomeListError: ${failure.message}");
          emit(IncomeListError(_mapFailureToMessage(failure)));
        },
        (incomes) {
          debugPrint(
              "[IncomeListBloc] Emitting IncomeListLoaded with ${incomes.length} incomes.");
          emit(IncomeListLoaded(
            incomes: incomes,
            filterStartDate: _currentStartDate,
            filterEndDate: _currentEndDate,
            filterCategory: _currentCategory,
            filterAccountId: _currentAccountId,
          ));
        },
      );
    } catch (e, s) {
      debugPrint(
          "[IncomeListBloc] *** CRITICAL ERROR in _onLoadIncomes: $e\n$s");
      emit(IncomeListError(
          "An unexpected error occurred in the Income BLoC: $e"));
    } finally {
      debugPrint(
          "[IncomeListBloc] Finished processing LoadIncomes event handler.");
    }
  }

  Future<void> _onFilterIncomes(
      FilterIncomes event, Emitter<IncomeListState> emit) async {
    debugPrint("[IncomeListBloc] Received FilterIncomes event.");
    emit(IncomeListLoading());

    // Update filters
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentCategory = event.category;
    _currentAccountId = event.accountId;
    debugPrint(
        "[IncomeListBloc] Filters updated: AccID=$_currentAccountId, Start=$_currentStartDate, End=$_currentEndDate, Cat=$_currentCategory");

    final params = GetIncomesParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      category: _currentCategory,
      accountId: _currentAccountId,
    );
    debugPrint(
        "[IncomeListBloc] Calling GetIncomesUseCase with new filters...");

    try {
      final result = await _getIncomesUseCase(params);
      debugPrint(
          "[IncomeListBloc] GetIncomesUseCase returned after filter. Result isLeft: ${result.isLeft()}");

      result.fold(
        (failure) {
          debugPrint(
              "[IncomeListBloc] Emitting IncomeListError after filter: ${failure.message}");
          emit(IncomeListError(_mapFailureToMessage(failure)));
        },
        (incomes) {
          debugPrint(
              "[IncomeListBloc] Emitting IncomeListLoaded after filter with ${incomes.length} incomes.");
          emit(IncomeListLoaded(
            incomes: incomes,
            filterStartDate: _currentStartDate,
            filterEndDate: _currentEndDate,
            filterCategory: _currentCategory,
            filterAccountId: _currentAccountId,
          ));
        },
      );
    } catch (e, s) {
      debugPrint(
          "[IncomeListBloc] *** CRITICAL ERROR in _onFilterIncomes: $e\n$s");
      emit(IncomeListError(
          "An unexpected error occurred while filtering income: $e"));
    } finally {
      debugPrint(
          "[IncomeListBloc] Finished processing FilterIncomes event handler.");
    }
  }

  Future<void> _onDeleteIncomeRequested(
      DeleteIncomeRequested event, Emitter<IncomeListState> emit) async {
    debugPrint(
        "[IncomeListBloc] Received DeleteIncomeRequested for ID: ${event.incomeId}");
    final currentState = state;
    if (currentState is IncomeListLoaded) {
      debugPrint(
          "[IncomeListBloc] Current state is Loaded. Proceeding with optimistic delete.");
      // Optimistic UI Update
      final optimisticList = currentState.incomes
          .where((inc) => inc.id != event.incomeId)
          .toList();
      debugPrint(
          "[IncomeListBloc] Optimistic list size: ${optimisticList.length}. Emitting updated IncomeListLoaded.");
      emit(IncomeListLoaded(
        incomes: optimisticList,
        filterStartDate: currentState.filterStartDate,
        filterEndDate: currentState.filterEndDate,
        filterCategory: currentState.filterCategory,
        filterAccountId: currentState.filterAccountId,
      ));

      try {
        final result =
            await _deleteIncomeUseCase(DeleteIncomeParams(event.incomeId));
        debugPrint(
            "[IncomeListBloc] DeleteIncomeUseCase returned. Result isLeft: ${result.isLeft()}");

        result.fold(
          (failure) {
            debugPrint(
                "[IncomeListBloc] Deletion failed: ${failure.message}. Reverting UI and emitting Error.");
            // Revert UI and show error
            emit(currentState);
            emit(IncomeListError(
                "Failed to delete income: ${_mapFailureToMessage(failure)}"));
          },
          (_) {
            debugPrint("[IncomeListBloc] Deletion successful (Optimistic UI).");
            // Important: Also trigger AccountListBloc/DashboardBloc refresh (Handled in UI layer now)
          },
        );
      } catch (e, s) {
        debugPrint(
            "[IncomeListBloc] *** CRITICAL ERROR in _onDeleteIncomeRequested: $e\n$s");
        emit(currentState); // Revert optimistic update on error
        emit(IncomeListError(
            "An unexpected error occurred during income deletion: $e"));
      }
    } else {
      debugPrint(
          "[IncomeListBloc] Delete requested but state is not IncomeListLoaded. Ignoring.");
    }
    debugPrint("[IncomeListBloc] Finished processing DeleteIncomeRequested.");
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      default:
        return 'An unexpected error occurred: ${failure.message}';
    }
  }
}
