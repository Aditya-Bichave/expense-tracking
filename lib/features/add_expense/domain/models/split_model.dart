import 'package:equatable/equatable.dart';

enum SplitType {
  // ignore: constant_identifier_names
  PERCENT,
  // ignore: constant_identifier_names
  EQUAL,
  // ignore: constant_identifier_names
  EXACT,
  // ignore: constant_identifier_names
  SHARE;

  String toJson() => name;
}

class SplitModel extends Equatable {
  final String userId;
  final SplitType shareType;
  final double shareValue; // The input value (%, amount, share count)
  final double computedAmount; // The calculated currency amount

  const SplitModel({
    required this.userId,
    required this.shareType,
    required this.shareValue,
    required this.computedAmount,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'share_type': shareType.toJson(),
    'share_value': shareValue,
    'computed_amount': computedAmount,
  };

  SplitModel copyWith({
    String? userId,
    SplitType? shareType,
    double? shareValue,
    double? computedAmount,
  }) {
    return SplitModel(
      userId: userId ?? this.userId,
      shareType: shareType ?? this.shareType,
      shareValue: shareValue ?? this.shareValue,
      computedAmount: computedAmount ?? this.computedAmount,
    );
  }

  @override
  List<Object?> get props => [userId, shareType, shareValue, computedAmount];
}
