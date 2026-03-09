import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

sealed class RecordSettlementEvent extends Equatable {
  const RecordSettlementEvent();

  @override
  List<Object?> get props => [];
}

class AmountChanged extends RecordSettlementEvent {
  final double amount;

  const AmountChanged(this.amount);

  @override
  List<Object?> get props => [amount];
}

class NoteChanged extends RecordSettlementEvent {
  final String note;

  const NoteChanged(this.note);

  @override
  List<Object?> get props => [note];
}

class ImageAttached extends RecordSettlementEvent {
  final XFile image;

  const ImageAttached(this.image);

  @override
  List<Object?> get props => [image];
}

class RemoveImage extends RecordSettlementEvent {}

class SubmitSettlement extends RecordSettlementEvent {
  final String groupId;
  final String receiverId;
  final String currency;

  const SubmitSettlement({
    required this.groupId,
    required this.receiverId,
    required this.currency,
  });

  @override
  List<Object?> get props => [groupId, receiverId, currency];
}

class ConfirmReturnedFromUpi extends RecordSettlementEvent {}
