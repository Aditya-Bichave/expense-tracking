import 'dart:async'; // Import async
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetFinancialOverviewUseCase _getFinancialOverviewUseCase;
  late final StreamSubscription<DataChangedEvent> _dataChangeSubscription;

  DashboardBloc({
    required GetFinancialOverviewUseCase getFinancialOverviewUseCase,
    required Stream<DataChangedEvent> dataChangeStream, // Inject stream
  })  : _getFinancialOverviewUseCase = getFinancialOverviewUseCase,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<_DataChanged>(_onDataChanged); // Handler for internal event

    // *** Subscribe to the stream ***
    _dataChangeSubscription = dataChangeStream.listen((event) {
      // Dashboard needs refresh on ANY data change affecting it
      debugPrint(
          "[DashboardBloc] Received DataChangedEvent: $event. Adding _DataChanged event.");
      add(const _DataChanged());
    });
    debugPrint("[DashboardBloc] Initialized and subscribed to data changes.");
  }

  // Internal event handler to trigger reload
  Future<void> _onDataChanged(
      _DataChanged event, Emitter<DashboardState> emit) async {
    debugPrint(
        "[DashboardBloc] Handling _DataChanged event. Dispatching LoadDashboard.");
    // Pass dates if you want to preserve filters during auto-refresh, otherwise load fresh
    add(const LoadDashboard(forceReload: true));
  }

  Future<void> _onLoadDashboard(
      LoadDashboard event, Emitter<DashboardState> emit) async {
    // Optionally avoid flicker if already loaded, unless forced
    if (state is! DashboardLoaded || event.forceReload) {
      if (state is! DashboardLoaded) {
        debugPrint(
            "[DashboardBloc] Current state is not Loaded. Emitting DashboardLoading.");
        emit(DashboardLoading());
      } else {
        debugPrint("[DashboardBloc] Force reload requested. Refreshing data.");
        // Consider a distinct 'Refreshing' state if needed
      }
    } else {
      debugPrint(
          "[DashboardBloc] State is Loaded, refreshing without Loading state.");
    }

    final params = GetFinancialOverviewParams(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    final result = await _getFinancialOverviewUseCase(params);

    result.fold(
      (failure) {
        debugPrint(
            "[DashboardBloc] Load failed: ${failure.message}. Emitting DashboardError.");
        emit(DashboardError(_mapFailureToMessage(failure)));
      },
      (overview) {
        debugPrint(
            "[DashboardBloc] Load successful. Emitting DashboardLoaded.");
        emit(DashboardLoaded(overview));
      },
    );
    debugPrint("[DashboardBloc] Finished processing LoadDashboard.");
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      // Add specific failures if the overview use case returns them
      default:
        return 'An unexpected error occurred loading dashboard: ${failure.message}';
    }
  }

  // *** Cancel subscription when BLoC is closed ***
  @override
  Future<void> close() {
    _dataChangeSubscription.cancel();
    debugPrint("[DashboardBloc] Canceled data change subscription.");
    return super.close();
  }
}
