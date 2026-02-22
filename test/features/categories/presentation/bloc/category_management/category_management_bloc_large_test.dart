import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';

void main() {
  test('CategoryManagementState supports equality', () {
    expect(
      const CategoryManagementState(),
      equals(const CategoryManagementState()),
    );
  });
}
