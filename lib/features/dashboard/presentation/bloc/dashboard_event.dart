part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final DateTime? startDate; // Optional filters for period summary
  final DateTime? endDate;

  const LoadDashboard({this.startDate, this.endDate});
  @override
  List<Object?> get props => [startDate, endDate];
}
