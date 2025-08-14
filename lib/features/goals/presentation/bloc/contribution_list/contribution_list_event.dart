part of 'contribution_list_bloc.dart';

abstract class ContributionListEvent extends Equatable {
  const ContributionListEvent();

  @override
  List<Object?> get props => [];
}

class LoadContributions extends ContributionListEvent {
  final bool forceReload;
  const LoadContributions({this.forceReload = false});

  @override
  List<Object?> get props => [forceReload];
}

class _ContributionsDataChanged extends ContributionListEvent {
  const _ContributionsDataChanged();
}
