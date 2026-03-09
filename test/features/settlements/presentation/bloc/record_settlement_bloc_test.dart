import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/services/image_compression_service.dart';
import 'package:expense_tracker/features/settlements/presentation/bloc/record_settlement_bloc.dart';
import 'package:expense_tracker/features/settlements/presentation/bloc/record_settlement_event.dart';
import 'package:expense_tracker/features/settlements/presentation/bloc/record_settlement_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthSessionService extends Mock implements AuthSessionService {}

class MockImageCompressionService extends Mock
    implements ImageCompressionService {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockAuthSessionService mockAuthSessionService;
  late MockImageCompressionService mockImageCompressionService;
  late RecordSettlementBloc bloc;
  late MockUser mockUser;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuthSessionService = MockAuthSessionService();
    mockImageCompressionService = MockImageCompressionService();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user1');
    when(() => mockAuthSessionService.currentUser).thenReturn(mockUser);

    bloc = RecordSettlementBloc(
      supabase: mockSupabase,
      authSessionService: mockAuthSessionService,
      imageCompressionService: mockImageCompressionService,
      initialAmount: 100.0,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('RecordSettlementBloc', () {
    test('initial state has correct amount', () {
      expect(bloc.state.amount, 100.0);
      expect(bloc.state.status, FormStatus.initial);
    });

    blocTest<RecordSettlementBloc, RecordSettlementState>(
      'emits updated amount and editing status on AmountChanged',
      build: () => bloc,
      act: (bloc) => bloc.add(const AmountChanged(50.0)),
      expect: () => [
        isA<RecordSettlementState>()
            .having((s) => s.amount, 'amount', 50.0)
            .having((s) => s.status, 'status', FormStatus.editing),
      ],
    );

    blocTest<RecordSettlementBloc, RecordSettlementState>(
      'ignores SubmitSettlement if already processing',
      build: () => bloc,
      seed: () => const RecordSettlementState(status: FormStatus.processing),
      act: (bloc) => bloc.add(
        const SubmitSettlement(
          groupId: 'group1',
          receiverId: 'user2',
          currency: 'INR',
        ),
      ),
      expect: () => [],
    );

    blocTest<RecordSettlementBloc, RecordSettlementState>(
      'emits processing then failure if user not logged in',
      build: () {
        when(() => mockAuthSessionService.currentUser).thenReturn(null);
        return bloc;
      },
      act: (bloc) => bloc.add(
        const SubmitSettlement(
          groupId: 'group1',
          receiverId: 'user2',
          currency: 'INR',
        ),
      ),
      expect: () => [
        isA<RecordSettlementState>().having(
          (s) => s.status,
          'status',
          FormStatus.processing,
        ),
        isA<RecordSettlementState>()
            .having((s) => s.status, 'status', FormStatus.failure)
            .having(
              (s) => s.errorMessage,
              'error',
              contains('User not logged in'),
            ),
      ],
    );
  });
}
