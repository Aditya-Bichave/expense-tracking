part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {
  final bool
  isReloading; // True if loading triggered while data was already loaded
  const DashboardLoading({this.isReloading = false});

  @override
  List<Object> get props => [isReloading];
}

class DashboardLoaded extends DashboardState {
  final FinancialOverview overview;

  const DashboardLoaded(this.overview);

  @override
  List<Object?> get props => [overview];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
