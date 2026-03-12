import 'package:equatable/equatable.dart';

sealed class GroupBalancesEvent extends Equatable {
  const GroupBalancesEvent();

  @override
  List<Object?> get props => [];
}

class FetchBalances extends GroupBalancesEvent {
  final String groupId;

  const FetchBalances(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class RefreshBalances extends GroupBalancesEvent {
  final String groupId;

  const RefreshBalances(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class ApplyOptimisticSettlement extends GroupBalancesEvent {
  final double amount;
  final String fromUserId;
  final String toUserId;

  const ApplyOptimisticSettlement({
    required this.amount,
    required this.fromUserId,
    required this.toUserId,
  });

  @override
  List<Object?> get props => [amount, fromUserId, toUserId];
}

class BalancesRealtimeUpdated extends GroupBalancesEvent {
  const BalancesRealtimeUpdated();
}
