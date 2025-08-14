part of 'data_management_bloc.dart';

abstract class DataManagementEvent extends Equatable {
  const DataManagementEvent();

  @override
  List<Object?> get props => [];
}

class BackupRequested extends DataManagementEvent {
  final String password;
  const BackupRequested(this.password);

  @override
  List<Object?> get props => [password];
}

class RestoreRequested extends DataManagementEvent {
  final String password;
  const RestoreRequested(this.password);

  @override
  List<Object?> get props => [password];
}

class ClearDataRequested extends DataManagementEvent {
  const ClearDataRequested();
}

// Event to clear the message after it's shown
class ClearDataManagementMessage extends DataManagementEvent {
  const ClearDataManagementMessage();
}
