import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';

abstract class CreateGroupEvent extends Equatable {
  const CreateGroupEvent();

  @override
  List<Object> get props => [];
}

class CreateGroupSubmitted extends CreateGroupEvent {
  final String name;
  final GroupType type;
  final String currency;
  final String userId;

  const CreateGroupSubmitted({
    required this.name,
    required this.type,
    required this.currency,
    required this.userId,
  });

  @override
  List<Object> get props => [name, type, currency, userId];
}
