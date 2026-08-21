import 'package:equatable/equatable.dart';

enum TrashItemType { expense, income }

class TrashItem extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final DateTime deletedAt;
  final TrashItemType type;

  const TrashItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.deletedAt,
    required this.type,
  });

  @override
  List<Object?> get props => [id, title, amount, date, deletedAt, type];
}

abstract class TrashBinEvent extends Equatable {
  const TrashBinEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrash extends TrashBinEvent {}

class RestoreItem extends TrashBinEvent {
  final String id;
  final TrashItemType type;

  const RestoreItem({required this.id, required this.type});

  @override
  List<Object?> get props => [id, type];
}

class PurgeItem extends TrashBinEvent {
  final String id;
  final TrashItemType type;

  const PurgeItem({required this.id, required this.type});

  @override
  List<Object?> get props => [id, type];
}
