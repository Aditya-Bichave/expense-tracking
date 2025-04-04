part of 'data_management_bloc.dart';

enum DataManagementStatus { initial, loading, success, error }

class DataManagementState extends Equatable {
  final DataManagementStatus status;
  final String? message; // For success or error messages

  const DataManagementState({
    this.status = DataManagementStatus.initial,
    this.message,
  });

  DataManagementState copyWith({
    DataManagementStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return DataManagementState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, message];
}
