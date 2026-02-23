import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:go_router/src/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockBox<T> extends Mock implements Box<T> {}

class MockHiveInterface extends Mock implements HiveInterface {}

class MockSession extends Mock implements Session {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockGoRouter extends Mock implements GoRouter {}

class MockGoRouterProvider extends StatelessWidget {
  const MockGoRouterProvider({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InheritedGoRouter(goRouter: router, child: child);
  }
}
