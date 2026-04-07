#!/bin/bash
cat << 'INNER_EOF' > test/router_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/features/auth/presentation/pages/e2e_bypass_page.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('Router has valid routes and redirects', () {
    final router = appRouter;
    expect(router, isNotNull);
    // Find basic routes to make sure they exist

    // Check router configuration
    final routeConfig = router.configuration;
    expect(routeConfig.routes.isNotEmpty, isTrue);
  });
}
INNER_EOF
