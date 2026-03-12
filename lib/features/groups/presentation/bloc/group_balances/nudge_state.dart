import 'package:equatable/equatable.dart';

abstract class NudgeState extends Equatable {
  const NudgeState();

  @override
  List<Object?> get props => [];
}

class NudgeInitial extends NudgeState {}

class NudgeSending extends NudgeState {
  final String userId;
  const NudgeSending(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NudgeSuccess extends NudgeState {
  final String userId;
  const NudgeSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

class NudgeFailure extends NudgeState {
  final String userId;
  final String message;
  const NudgeFailure({required this.userId, required this.message});

  @override
  List<Object?> get props => [userId, message];
}
