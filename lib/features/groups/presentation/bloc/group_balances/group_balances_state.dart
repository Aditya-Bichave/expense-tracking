import 'package:equatable/equatable.dart';
import '../../../domain/entities/group_balances.dart';

sealed class GroupBalancesState extends Equatable {
  const GroupBalancesState();

  @override
  List<Object?> get props => [];
}

class GroupBalancesLoading extends GroupBalancesState {
  const GroupBalancesLoading();
}

class GroupBalancesLoaded extends GroupBalancesState {
  final GroupBalances balances;
  final bool isRefreshing;

  const GroupBalancesLoaded(this.balances, {this.isRefreshing = false});

  @override
  List<Object?> get props => [balances, isRefreshing];

  GroupBalancesLoaded copyWith({GroupBalances? balances, bool? isRefreshing}) {
    return GroupBalancesLoaded(
      balances ?? this.balances,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class GroupBalancesError extends GroupBalancesState {
  final String message;

  const GroupBalancesError(this.message);

  @override
  List<Object?> get props => [message];
}
