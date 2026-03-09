import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockFunctionsClient mockFunctions;
  late NudgeBloc bloc;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockSupabase.functions).thenReturn(mockFunctions);
    bloc = NudgeBloc(supabase: mockSupabase);
  });

  tearDown(() {
    bloc.close();
  });

  group('NudgeBloc', () {
    const debt = SimplifiedDebt(
      fromUserId: 'user1',
      toUserId: 'me',
      amount: 100.0,
      fromUserName: 'Alice',
      toUserName: 'You',
    );

    test('initial state is NudgeInitial', () {
      expect(bloc.state, isA<NudgeInitial>());
    });

    blocTest<NudgeBloc, NudgeState>(
      'emits [NudgeSending, NudgeSuccess] on success',
      build: () {
        when(
          () => mockFunctions.invoke('send-nudge', body: any(named: 'body')),
        ).thenAnswer((_) async => FunctionResponse(status: 200));
        return bloc;
      },
      act: (bloc) => bloc.add(const SendNudge(groupId: 'group1', debt: debt)),
      expect: () => [const NudgeSending('user1'), const NudgeSuccess('user1')],
    );

    blocTest<NudgeBloc, NudgeState>(
      'emits [NudgeSending, NudgeFailure] on rate limit',
      build: () {
        when(
          () => mockFunctions.invoke('send-nudge', body: any(named: 'body')),
        ).thenThrow(FunctionException(status: 429));
        return bloc;
      },
      act: (bloc) => bloc.add(const SendNudge(groupId: 'group1', debt: debt)),
      expect: () => [
        const NudgeSending('user1'),
        isA<NudgeFailure>().having(
          (s) => s.message,
          'message',
          contains('every few minutes'),
        ),
      ],
    );

    blocTest<NudgeBloc, NudgeState>(
      'emits [NudgeSending, NudgeFailure] on no devices',
      build: () {
        when(
          () => mockFunctions.invoke('send-nudge', body: any(named: 'body')),
        ).thenThrow(FunctionException(status: 404));
        return bloc;
      },
      act: (bloc) => bloc.add(const SendNudge(groupId: 'group1', debt: debt)),
      expect: () => [
        const NudgeSending('user1'),
        isA<NudgeFailure>().having(
          (s) => s.message,
          'message',
          contains('registered devices'),
        ),
      ],
    );

    blocTest<NudgeBloc, NudgeState>(
      'emits [NudgeSending, NudgeFailure] on general error',
      build: () {
        when(
          () => mockFunctions.invoke('send-nudge', body: any(named: 'body')),
        ).thenThrow(Exception('Unknown error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const SendNudge(groupId: 'group1', debt: debt)),
      expect: () => [
        const NudgeSending('user1'),
        isA<NudgeFailure>().having(
          (s) => s.message,
          'message',
          contains('Unknown error'),
        ),
      ],
    );
  });
}
