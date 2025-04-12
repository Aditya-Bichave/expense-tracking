part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final DateTime? startDate; // Optional filters for period summary
  final DateTime? endDate;
  final bool forceReload; // Flag to force past the "already loaded" check

  const LoadDashboard({this.startDate, this.endDate, this.forceReload = false});
  @override
  List<Object?> get props => [startDate, endDate, forceReload];
}

// Internal event triggered by stream listener
class _DataChanged extends DashboardEvent {
  const _DataChanged();
}

// --- ADDED: Reset State Event ---
class ResetState extends DashboardEvent {
  const ResetState();
}
// --- END ADDED ---
