part of 'deep_link_bloc.dart';

abstract class DeepLinkState extends Equatable {
  const DeepLinkState();

  @override
  List<Object?> get props => [];
}

class DeepLinkInitial extends DeepLinkState {}

class DeepLinkProcessing extends DeepLinkState {}

class DeepLinkSuccess extends DeepLinkState {
  final String groupId;
  final String? groupName;

  const DeepLinkSuccess({required this.groupId, this.groupName});

  @override
  List<Object?> get props => [groupId, groupName];
}

class DeepLinkError extends DeepLinkState {
  final String message;

  const DeepLinkError(this.message);

  @override
  List<Object?> get props => [message];
}
