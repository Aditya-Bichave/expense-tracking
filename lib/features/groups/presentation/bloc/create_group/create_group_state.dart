import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';

abstract class CreateGroupState extends Equatable {
  const CreateGroupState();

  @override
  List<Object?> get props => [];
}

class CreateGroupInitial extends CreateGroupState {}

class CreateGroupLoading extends CreateGroupState {}

class CreateGroupSuccess extends CreateGroupState {
  final GroupEntity group;

  const CreateGroupSuccess(this.group);

  @override
  List<Object?> get props => [group];
}

class CreateGroupFailure extends CreateGroupState {
  final String message;

  const CreateGroupFailure(this.message);

  @override
  List<Object?> get props => [message];
}
