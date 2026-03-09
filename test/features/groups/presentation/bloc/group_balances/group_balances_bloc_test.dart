import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_balances.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockAuthSessionService extends Mock implements AuthSessionService {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockFunctionsClient mockFunctions;
  late MockAuthSessionService mockAuthSessionService;
  late StreamController<dynamic> mockDataChangeController;
  late GroupBalancesBloc bloc;
  late MockUser mockUser;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    mockAuthSessionService = MockAuthSessionService();
    mockDataChangeController = StreamController<dynamic>.broadcast();
    mockUser = MockUser();

    when(() => mockSupabase.functions).thenReturn(mockFunctions);
    when(() => mockUser.id).thenReturn('user1');
    when(() => mockAuthSessionService.currentUser).thenReturn(mockUser);

    bloc = GroupBalancesBloc(
      supabase: mockSupabase,
      authSessionService: mockAuthSessionService,
      dataChangeStream: mockDataChangeController.stream,
    );
  });

  tearDown(() {
    bloc.close();
    mockDataChangeController.close();
  });

  group('GroupBalancesBloc', () {
    const groupId = 'group1';

    test('initial state is GroupBalancesLoading', () {
      expect(bloc.state, isA<GroupBalancesLoading>());
    });

    blocTest<GroupBalancesBloc, GroupBalancesState>(
      'emits [GroupBalancesLoading, GroupBalancesLoaded] on FetchBalances success',
      build: () {
        when(
          () => mockFunctions.invoke(
            'simplify-debts',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: {
              'my_net_balance': 100.0,
              'simplified_debts': [
                {
                  'from_user_id': 'user2',
                  'to_user_id': 'user1',
                  'amount': 100.0,
                  'from_user_name': 'Bob',
                  'to_user_name': 'Alice',
                },
              ],
            },
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchBalances(groupId)),
      expect: () => [isA<GroupBalancesLoading>(), isA<GroupBalancesLoaded>()],
      verify: (_) {
        final state = bloc.state as GroupBalancesLoaded;
        expect(state.balances.myNetBalance, 100.0);
        expect(state.balances.simplifiedDebts.length, 1);
      },
    );

    blocTest<GroupBalancesBloc, GroupBalancesState>(
      'emits mock data on FetchBalances if edge function fails',
      build: () {
        when(
          () => mockFunctions.invoke(
            'simplify-debts',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(Exception('Not deployed'));
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchBalances(groupId)),
      expect: () => [
        isA<GroupBalancesLoading>(),
        isA<GroupBalancesLoaded>(), // Mock data fallback
      ],
      verify: (_) {
        final state = bloc.state as GroupBalancesLoaded;
        expect(state.balances.myNetBalance, -700.0);
      },
    );

    blocTest<GroupBalancesBloc, GroupBalancesState>(
      'emits optimistic UI update on ApplyOptimisticSettlement',
      build: () {
        when(
          () => mockFunctions.invoke(
            'simplify-debts',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(Exception('Not deployed'));
        return bloc;
      },
      seed: () => const GroupBalancesLoaded(
        GroupBalances(
          myNetBalance: -100.0,
          simplifiedDebts: [
            SimplifiedDebt(
              fromUserId: 'user1',
              toUserId: 'user2',
              amount: 100.0,
              fromUserName: 'Alice',
              toUserName: 'Bob',
            ),
          ],
        ),
      ),
      act: (bloc) => bloc.add(
        const ApplyOptimisticSettlement(
          amount: 50.0,
          fromUserId: 'user1',
          toUserId: 'user2',
        ),
      ),
      expect: () => [
        isA<GroupBalancesLoaded>().having(
          (s) => s.balances.myNetBalance,
          'myNetBalance',
          -50.0,
        ), // -100 + 50
      ],
    );
  });
}
