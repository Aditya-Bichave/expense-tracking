import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'dart:async';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthSessionService extends Mock implements AuthSessionService {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockFunctionResponse extends Mock implements FunctionResponse {}

void main() {
  late GroupBalancesBloc bloc;
  late MockSupabaseClient mockSupabase;
  late MockAuthSessionService mockAuthSession;
  late MockFunctionsClient mockFunctions;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuthSession = MockAuthSessionService();
    mockFunctions = MockFunctionsClient();
    when(() => mockSupabase.functions).thenReturn(mockFunctions);

    bloc = GroupBalancesBloc(
      supabase: mockSupabase,
      authSessionService: mockAuthSession,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('does not emit if closed', () async {
    final mockResponse = MockFunctionResponse();
    when(
      () => mockResponse.data,
    ).thenReturn({'myNetBalance': 10.0, 'simplifiedDebts': []});

    // Simulate a delayed response
    when(
      () => mockFunctions.invoke(
        'simplify-debts',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 50));
      return mockResponse;
    });

    bloc.add(const FetchBalances('group-1'));
    // Close it before the delayed response comes back
    await Future.delayed(const Duration(milliseconds: 10));
    bloc.close();

    await Future.delayed(const Duration(milliseconds: 100));
    // It should still be in the loading state and not transition to Loaded
    expect(bloc.state, isA<GroupBalancesLoading>());
  });
}
