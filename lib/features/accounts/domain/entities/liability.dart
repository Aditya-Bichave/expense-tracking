import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability_enums.dart';

class Liability extends Equatable {
  final String id;
  final String name;
  final LiabilityType type;
  final double initialBalance;
  final double? creditLimit;
  final double? interestRate;
  final double currentBalance; // Calculated, not stored directly in DB model

  const Liability({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.creditLimit,
    this.interestRate,
    required this.currentBalance,
  });

  @override
  List<Object?> get props => [id, name, type, initialBalance, creditLimit, interestRate, currentBalance];
}
