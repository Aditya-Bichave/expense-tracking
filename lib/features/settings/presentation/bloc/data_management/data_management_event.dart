part of 'data_management_bloc.dart';

abstract class DataManagementEvent extends Equatable {
  const DataManagementEvent();

  @override
  List<Object?> get props => [];
}

class BackupRequested extends DataManagementEvent {
  const BackupRequested();
}

class RestoreRequested extends DataManagementEvent {
  const RestoreRequested();
}

class ClearDataRequested extends DataManagementEvent {
  const ClearDataRequested();
}

// Event to clear the message after it's shown
class ClearDataManagementMessage extends DataManagementEvent {
  const ClearDataManagementMessage();
}
