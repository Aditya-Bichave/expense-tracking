import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetFinancialOverviewUseCase _getFinancialOverviewUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  // Store current filters for potential future use (though not currently used for refresh)
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  DashboardBloc({
    required GetFinancialOverviewUseCase getFinancialOverviewUseCase,
    required Stream<DataChangedEvent> dataChangeStream,
  })  : _getFinancialOverviewUseCase = getFinancialOverviewUseCase,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<_DataChanged>(_onDataChanged);

    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Dashboard needs refresh on ANY data change affecting calculations or settings (currency)
      log.info(
          "[DashboardBloc] Received DataChangedEvent: $event. Triggering reload.");
      add(const _DataChanged());
    }, onError: (error, stackTrace) {
      log.severe("[DashboardBloc] Error in dataChangeStream listener");
    });
    log.info("[DashboardBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<DashboardState> emit) async {
    log.info(
        "[DashboardBloc] Handling _DataChanged event. Dispatching LoadDashboard(forceReload: true).");
    // Force reload to get fresh overview data
    add(const LoadDashboard(forceReload: true));
  }

  Future<void> _onLoadDashboard(
      LoadDashboard event, Emitter<DashboardState> emit) async {
    log.info(
        "[DashboardBloc] Received LoadDashboard event (forceReload: ${event.forceReload}). Current state: ${state.runtimeType}");

    // Update stored filters if provided in the event
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;

    // Show loading state only if not already loaded or forced
    if (state is! DashboardLoaded || event.forceReload) {
      emit(DashboardLoading(isReloading: state is DashboardLoaded));
      log.info(
          "[DashboardBloc] Emitting DashboardLoading (isReloading: ${state is DashboardLoaded}).");
    } else {
      log.info("[DashboardBloc] State is Loaded, refreshing data silently.");
    }

    final params = GetFinancialOverviewParams(
      startDate: _currentStartDate,
      endDate: _currentEndDate,
    );
    log.info(
        "[DashboardBloc] Calling GetFinancialOverviewUseCase with params: Start=${params.startDate}, End=${params.endDate}");

    final result = await _getFinancialOverviewUseCase(params);
    log.info(
        "[DashboardBloc] GetFinancialOverviewUseCase returned. isLeft: ${result.isLeft()}");

    result.fold(
      (failure) {
        log.warning(
            "[DashboardBloc] Load failed: ${failure.message}. Emitting DashboardError.");
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
        "[DashboardBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case CacheFailure:
      case SettingsFailure: // Settings failure might impact currency display
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
