import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackupRequested supports equality', () {
    expect(const BackupRequested('pw'), const BackupRequested('pw'));
  });

  test('RestoreRequested supports equality', () {
    expect(const RestoreRequested('pw'), const RestoreRequested('pw'));
  });
}
