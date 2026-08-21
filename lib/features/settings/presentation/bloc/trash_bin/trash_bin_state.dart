import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/trash_bin/trash_bin_event.dart';

abstract class TrashBinState extends Equatable {
  const TrashBinState();

  @override
  List<Object?> get props => [];
}

class TrashBinInitial extends TrashBinState {}

class TrashBinLoading extends TrashBinState {}

class TrashBinLoaded extends TrashBinState {
  final List<TrashItem> items;

  const TrashBinLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class TrashBinEmpty extends TrashBinState {}

class TrashBinError extends TrashBinState {
  final String message;

  const TrashBinError(this.message);

  @override
  List<Object?> get props => [message];
}
