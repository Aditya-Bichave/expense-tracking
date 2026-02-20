import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DataManagementState equality works', () {
    expect(const DataManagementState(), const DataManagementState());
  });

  test('DataManagementState copyWith works', () {
    const state = DataManagementState();
    final newState = state.copyWith(status: DataManagementStatus.loading);
    expect(newState.status, DataManagementStatus.loading);
  });
}
