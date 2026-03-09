import 'package:equatable/equatable.dart';
import 'simplified_debt.dart';

class GroupBalances extends Equatable {
  final double myNetBalance;
  final List<SimplifiedDebt> simplifiedDebts;

  const GroupBalances({
    required this.myNetBalance,
    required this.simplifiedDebts,
  });

  factory GroupBalances.fromJson(Map<String, dynamic> json) {
    return GroupBalances(
      myNetBalance: (json['my_net_balance'] as num).toDouble(),
      simplifiedDebts:
          (json['simplified_debts'] as List<dynamic>?)
              ?.map((e) => SimplifiedDebt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [myNetBalance, simplifiedDebts];
}
