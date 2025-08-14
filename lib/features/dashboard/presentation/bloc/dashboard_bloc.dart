// lib/features/dashboard/presentation/bloc/dashboard_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // Import TransactionEntity for recent list

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetFinancialOverviewUseCase _getFinancialOverviewUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  // Keep track of current filters (even if only monthly used currently)
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  DashboardBloc({
    required GetFinancialOverviewUseCase getFinancialOverviewUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  }) : _getFinancialOverviewUseCase = getFinancialOverviewUseCase,
       super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<_DataChanged>(_onDataChanged);
    on<ResetState>(_onResetState); // Add Handler

    _dataChangeSubscription = dataChangeStream.listen(
      (event) {
        // --- MODIFIED Listener ---
        if (event.type == DataChangeType.system &&
            event.reason == DataChangeReason.reset) {
          log.info(
            "[DashboardBloc] System Reset event received. Adding ResetState.",
          );
          add(const ResetState());
        } else if (event.type == DataChangeType.account ||
            event.type == DataChangeType.expense ||
            event.type == DataChangeType.income ||
            event.type == DataChangeType.budget ||
            event.type == DataChangeType.goal ||
            event.type == DataChangeType.goalContribution ||
            event.type == DataChangeType.settings ||
            (event.type == DataChangeType.system &&
                event.reason == DataChangeReason.updated)) {
          log.info(
            "[DashboardBloc] Relevant DataChangedEvent: $event. Triggering reload.",
          );
          add(const _DataChanged());
        }
        // --- END MODIFIED ---
      },
      onError: (error, stackTrace) {
        log.severe(
          "[DashboardBloc] Error in dataChangeStream listener: $error",
        );
      },
    );
    log.info("[DashboardBloc] Initialized and subscribed to data changes.");
  }

  // --- ADDED: Reset State Handler ---
  void _onResetState(ResetState event, Emitter<DashboardState> emit) {
    log.info("[DashboardBloc] Resetting state to initial.");
    emit(DashboardInitial());
    add(const LoadDashboard()); // Trigger initial load after reset
  }
  // --- END ADDED ---

  // ... (rest of handlers remain the same) ...
  Future<void> _onDataChanged(
    _DataChanged event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoading) {
      // Avoid triggering multiple loads
      log.info("[DashboardBloc] Handling _DataChanged event.");
      add(const LoadDashboard(forceReload: true));
    } else {
      log.fine(
        "[DashboardBloc] _DataChanged received, but already loading. Skipping explicit reload.",
      );
    }
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    log.info(
      "[DashboardBloc] Received LoadDashboard event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}",
    );

    // Set default date range to current month if not provided
    final now = DateTime.now();
    final startDate = event.startDate ?? DateTime(now.year, now.month, 1);
    final endDate =
        event.endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Update stored filters
    _currentStartDate = startDate;
    _currentEndDate = endDate;

    // Show loading state only if not already loaded or forced
    if (state is! DashboardLoaded || event.forceReload) {
      emit(DashboardLoading(isReloading: state is DashboardLoaded));
      log.info(
        "[DashboardBloc] Emitting DashboardLoading (isReloading: ${state is DashboardLoaded}).",
      );
    } else {
      log.info("[DashboardBloc] State is Loaded, refreshing data silently.");
    }

    // Use the determined (or defaulted) filters
    final params = GetFinancialOverviewParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
    );
    log.info(
      "[DashboardBloc] Calling GetFinancialOverviewUseCase with params: Start=${params.startDate}, End=${params.endDate}",
    );

    final result = await _getFinancialOverviewUseCase(params);
    log.info(
      "[DashboardBloc] GetFinancialOverviewUseCase returned. isLeft: ${result.isLeft()}",
    );

    result.fold(
      (failure) {
        log.warning(
          "[DashboardBloc] Load failed: ${failure.message}. Emitting DashboardError.",
        );
        emit(DashboardError(_mapFailureToMessage(failure)));
      },
      (overview) {
        log.info("[DashboardBloc] Load successful. Emitting DashboardLoaded.");
        emit(DashboardLoaded(overview));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
      "[DashboardBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure.runtimeType) {
      case CacheFailure:
      case SettingsFailure:
        return 'Database Error: Could not load dashboard data. ${failure.message}';
      case UnexpectedFailure:
        return 'An unexpected error occurred loading the dashboard.';
      default:
        return failure.message.isNotEmpty
            ? failure.message
            : 'An unknown error occurred.';
    }
  }

  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    log.info("[DashboardBloc] Canceled data change subscription and closing.");
    return super.close();
  }
}
