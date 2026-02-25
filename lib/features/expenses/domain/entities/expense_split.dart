import 'package:equatable/equatable.dart';

enum SplitType {
  equal,
  exact,
  percent,
  share;

  String get value => name.toUpperCase();
}

class ExpenseSplit extends Equatable {
  final String userId;
  final SplitType shareType;
  final double shareValue;
  final double computedAmount;

  const ExpenseSplit({
    required this.userId,
    required this.shareType,
    required this.shareValue,
    required this.computedAmount,
  });

  ExpenseSplit copyWith({
    String? userId,
    SplitType? shareType,
    double? shareValue,
    double? computedAmount,
  }) {
    return ExpenseSplit(
      userId: userId ?? this.userId,
      shareType: shareType ?? this.shareType,
      shareValue: shareValue ?? this.shareValue,
      computedAmount: computedAmount ?? this.computedAmount,
    );
  }

  @override
  List<Object?> get props => [userId, shareType, shareValue, computedAmount];
}
