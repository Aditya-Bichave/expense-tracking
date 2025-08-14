part of 'contribution_list_bloc.dart';

enum ContributionListStatus { initial, loading, success, error }

class ContributionListState extends Equatable {
  final ContributionListStatus status;
  final List<GoalContribution> contributions;
  final String? errorMessage;

  const ContributionListState({
    this.status = ContributionListStatus.initial,
    this.contributions = const [],
    this.errorMessage,
  });

  ContributionListState copyWith({
    ContributionListStatus? status,
    List<GoalContribution>? contributions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ContributionListState(
      status: status ?? this.status,
      contributions: contributions ?? this.contributions,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, contributions, errorMessage];
}
