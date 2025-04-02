part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props =>
      []; // Use Object? for potential nulls if needed in future states
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  // This 'overview' field holds the actual data fetched by the BLoC.
  // It's non-nullable based on your BLoC logic emitting this state only on success.
  final FinancialOverview overview;

  const DashboardLoaded(this.overview);

  @override
  List<Object?> get props => [overview];

  // --- REMOVED INCORRECT GETTER ---
  // get financialOverview => null; // <-- THIS WAS THE BUG CAUSING THE CRASH
  // Access the data directly via the 'overview' field: e.g., state.overview
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
