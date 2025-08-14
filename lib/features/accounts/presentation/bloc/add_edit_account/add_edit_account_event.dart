part of 'add_edit_account_bloc.dart';

abstract class AddEditAccountEvent extends Equatable {
  const AddEditAccountEvent();
  @override
  List<Object?> get props => [];
}

class SaveAccountRequested extends AddEditAccountEvent {
  final String name;
  final AssetType type;
  final double initialBalance;
  final String colorHex;
  final String? existingAccountId; // Null if adding

  const SaveAccountRequested({
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.colorHex,
    this.existingAccountId,
  });

  @override
  List<Object?> get props =>
      [name, type, initialBalance, colorHex, existingAccountId];
}
