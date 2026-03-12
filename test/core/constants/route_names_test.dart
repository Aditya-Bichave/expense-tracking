import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';

void main() {
  test('RouteNames values are correct', () {
    expect(RouteNames.dashboard, '/dashboard');
    expect(RouteNames.login, '/login');
    expect(RouteNames.groups, '/groups');
    expect(RouteNames.groupCreate, 'group_create');
    expect(RouteNames.groupEdit, 'group_edit');
    expect(RouteNames.groupDetail, 'group_detail');
  });
}
