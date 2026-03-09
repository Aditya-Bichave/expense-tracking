import 'package:expense_tracker/core/events/data_change_event.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/auth/auth_session_service.dart';

import 'package:expense_tracker/features/groups/domain/entities/group_balances.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'group_balances_event.dart';
import 'group_balances_state.dart';

class GroupBalancesBloc extends Bloc<GroupBalancesEvent, GroupBalancesState> {
  final SupabaseClient supabase;
  final AuthSessionService authSessionService;
  final Stream<DataChangedEvent>? dataChangeStream;
  StreamSubscription<DataChangedEvent>? _dataChangeSubscription;
  final _log = Logger('GroupBalancesBloc');
  String? _currentGroupId;

  GroupBalancesBloc({
    required this.supabase,
    required this.authSessionService,
    this.dataChangeStream,
  }) : super(const GroupBalancesLoading()) {
    on<FetchBalances>(_onFetchBalances);
    on<RefreshBalances>(_onRefreshBalances);
    on<ApplyOptimisticSettlement>(_onApplyOptimisticSettlement);
    on<BalancesRealtimeUpdated>(_onBalancesRealtimeUpdated);

    if (dataChangeStream != null) {
      _dataChangeSubscription = dataChangeStream!.listen((event) {
        if (event.type == DataChangeType.expense ||
            event.type == DataChangeType.system) {
          add(const BalancesRealtimeUpdated());
        }
      });
    }
  }

  @override
  Future<void> close() {
    _dataChangeSubscription?.cancel();
    return super.close();
  }

  Future<void> _onFetchBalances(
    FetchBalances event,
    Emitter<GroupBalancesState> emit,
  ) async {
    _currentGroupId = event.groupId;
    emit(const GroupBalancesLoading());
    await _fetchData(emit, event.groupId);
  }

  Future<void> _onRefreshBalances(
    RefreshBalances event,
    Emitter<GroupBalancesState> emit,
  ) async {
    _currentGroupId = event.groupId;
    if (state is GroupBalancesLoaded) {
      final current = state as GroupBalancesLoaded;
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const GroupBalancesLoading());
    }
    await _fetchData(emit, event.groupId);
  }

  Future<void> _onBalancesRealtimeUpdated(
    BalancesRealtimeUpdated event,
    Emitter<GroupBalancesState> emit,
  ) async {
    if (_currentGroupId != null) {
      add(RefreshBalances(_currentGroupId!));
    }
  }

  Future<void> _fetchData(
    Emitter<GroupBalancesState> emit,
    String groupId,
  ) async {
    try {
      final response = await supabase.functions.invoke(
        'simplify-debts',
        queryParameters: {'group_id': groupId},
      );

      final data = response.data;
      if (data != null && data is Map<String, dynamic>) {
        final balances = GroupBalances.fromJson(data);
        emit(GroupBalancesLoaded(balances));
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e, s) {
      _log.severe('Failed to fetch group balances', e, s);
      _log.info('Falling back to mock data');
      _emitMockData(emit);
    }
  }

  void _emitMockData(Emitter<GroupBalancesState> emit) {
    final currentUser = authSessionService.currentUser;
    final currentUserId = currentUser?.id ?? 'me';

    final mockBalances = GroupBalances(
      myNetBalance: -700.0,
      simplifiedDebts: [
        SimplifiedDebt(
          fromUserId: currentUserId,
          toUserId: 'user-ravi',
          amount: 1500.0,
          fromUserName: 'You',
          toUserName: 'Ravi',
          toUserUpi: 'ravi@okicici',
        ),
        SimplifiedDebt(
          fromUserId: 'user-amit',
          toUserId: currentUserId,
          amount: 800.0,
          fromUserName: 'Amit',
          toUserName: 'You',
        ),
        SimplifiedDebt(
          fromUserId: 'user-zack',
          toUserId: 'user-cody',
          amount: 300.0,
          fromUserName: 'Zack',
          toUserName: 'Cody',
        ),
      ],
    );

    emit(GroupBalancesLoaded(mockBalances));
  }

  void _onApplyOptimisticSettlement(
    ApplyOptimisticSettlement event,
    Emitter<GroupBalancesState> emit,
  ) {
    if (state is GroupBalancesLoaded) {
      final currentState = state as GroupBalancesLoaded;
      final currentBalances = currentState.balances;
      final currentUserId = authSessionService.currentUser?.id ?? 'me';

      double netBalanceChange = 0;
      if (event.fromUserId == currentUserId) {
        netBalanceChange += event.amount;
      } else if (event.toUserId == currentUserId) {
        netBalanceChange -= event.amount;
      }

      double newNetBalance = currentBalances.myNetBalance + netBalanceChange;

      List<SimplifiedDebt> newDebts = [];
      for (var debt in currentBalances.simplifiedDebts) {
        if (debt.fromUserId == event.fromUserId &&
            debt.toUserId == event.toUserId) {
          final newAmount = debt.amount - event.amount;
          if (newAmount > 0.01) {
            newDebts.add(
              SimplifiedDebt(
                fromUserId: debt.fromUserId,
                toUserId: debt.toUserId,
                amount: newAmount,
                fromUserName: debt.fromUserName,
                toUserName: debt.toUserName,
                toUserUpi: debt.toUserUpi,
              ),
            );
          }
        } else {
          newDebts.add(debt);
        }
      }

      final newBalances = GroupBalances(
        myNetBalance: newNetBalance,
        simplifiedDebts: newDebts,
      );

      emit(GroupBalancesLoaded(newBalances));

      if (_currentGroupId != null) {
        Future.delayed(const Duration(milliseconds: 500))
            .then((_) {
              if (!isClosed) {
                add(RefreshBalances(_currentGroupId!));
              }
            })
            .catchError((e, s) {
              _log.severe('Error dispatching optimistic refresh', e, s);
            });
      }
    }
  }
}
