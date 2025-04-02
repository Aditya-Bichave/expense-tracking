import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetFinancialOverviewUseCase _getFinancialOverviewUseCase;

  DashboardBloc(
      {required GetFinancialOverviewUseCase getFinancialOverviewUseCase})
      : _getFinancialOverviewUseCase = getFinancialOverviewUseCase,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
  }

  Future<void> _onLoadDashboard(
      LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());

    final params = GetFinancialOverviewParams(
      startDate: event.startDate,
      endDate: event.endDate,
    );

    final result = await _getFinancialOverviewUseCase(params);

    result.fold(
      (failure) => emit(DashboardError(_mapFailureToMessage(failure))),
      (overview) => emit(DashboardLoaded(overview)),
    );
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
}
