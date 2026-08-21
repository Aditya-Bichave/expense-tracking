import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/di/service_configurations/groups_dependencies.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:expense_tracker/features/settlements/presentation/bloc/record_settlement_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthSessionService extends Mock implements AuthSessionService {}

class MockImageCompressionService extends Mock
    implements ImageCompressionService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<SupabaseClient>(() => MockSupabaseClient());
    sl.registerLazySingleton<AuthSessionService>(
      () => MockAuthSessionService(),
    );
    sl.registerLazySingleton<ImageCompressionService>(
      () => MockImageCompressionService(),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  test('GroupsDependencies registers RecordSettlementBloc factoryParam', () {
    GroupsDependencies.register();

    expect(sl.isRegistered<RecordSettlementBloc>(), isTrue);
    final bloc = sl<RecordSettlementBloc>(param1: 150.0);
    expect(bloc, isA<RecordSettlementBloc>());
    expect(bloc.state.amount, 150.0);
  });
}
