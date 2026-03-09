import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';

abstract class NudgeEvent extends Equatable {
  const NudgeEvent();

  @override
  List<Object?> get props => [];
}

class SendNudge extends NudgeEvent {
  final String groupId;
  final SimplifiedDebt debt;

  const SendNudge({required this.groupId, required this.debt});

  @override
  List<Object?> get props => [groupId, debt];
}
