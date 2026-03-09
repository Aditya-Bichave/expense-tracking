import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

enum FormStatus { initial, editing, processing, success, failure }

class RecordSettlementState extends Equatable {
  final double amount;
  final String note;
  final XFile? attachedImage;
  final FormStatus status;
  final String? errorMessage;
  final bool waitingForUpiConfirmation;

  const RecordSettlementState({
    this.amount = 0.0,
    this.note = '',
    this.attachedImage,
    this.status = FormStatus.initial,
    this.errorMessage,
    this.waitingForUpiConfirmation = false,
  });

  RecordSettlementState copyWith({
    double? amount,
    String? note,
    XFile? attachedImage,
    bool clearImage = false,
    FormStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? waitingForUpiConfirmation,
  }) {
    return RecordSettlementState(
      amount: amount ?? this.amount,
      note: note ?? this.note,
      attachedImage: clearImage ? null : (attachedImage ?? this.attachedImage),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      waitingForUpiConfirmation:
          waitingForUpiConfirmation ?? this.waitingForUpiConfirmation,
    );
  }

  @override
  List<Object?> get props => [
    amount,
    note,
    attachedImage?.path,
    status,
    errorMessage,
    waitingForUpiConfirmation,
  ];
}
