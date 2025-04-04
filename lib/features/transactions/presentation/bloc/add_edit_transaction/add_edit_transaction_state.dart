part of 'add_edit_transaction_bloc.dart';

enum AddEditStatus {
  initial,
  ready,
  loading,
  suggestingCategory,
  navigatingToCreateCategory,
  saving,
  success,
  error
}

class AddEditTransactionState extends Equatable {
  final AddEditStatus status;
  final TransactionType transactionType;
  final TransactionEntity? initialTransaction;
  final String? errorMessage;
  final Category? suggestedCategory;
  final Category? newlyCreatedCategory;

  // --- ADDED FLAG ---
  final bool askCreateCategory; // Flag to signal UI to show the dialog

  final String? tempTitle;
  final double? tempAmount;
  final DateTime? tempDate;
  final String? tempAccountId;
  final String? tempNotes;

  const AddEditTransactionState({
    this.status = AddEditStatus.initial,
    this.transactionType = TransactionType.expense,
    this.initialTransaction,
    this.errorMessage,
    this.suggestedCategory,
    this.newlyCreatedCategory,
    // --- Default flag to false ---
    this.askCreateCategory = false,
    this.tempTitle,
    this.tempAmount,
    this.tempDate,
    this.tempAccountId,
    this.tempNotes,
  });

  bool get isEditing => initialTransaction != null;
  Category? get effectiveCategory =>
      newlyCreatedCategory ?? initialTransaction?.category;

  AddEditTransactionState copyWith({
    AddEditStatus? status,
    TransactionType? transactionType,
    TransactionEntity? initialTransaction,
    ValueGetter<String?>? errorMessage,
    ValueGetter<Category?>? suggestedCategory,
    ValueGetter<Category?>? newlyCreatedCategory,
    // --- ADDED flag to copyWith ---
    bool? askCreateCategory,
    String? tempTitle,
    double? tempAmount,
    DateTime? tempDate,
    String? tempAccountId,
    ValueGetter<String?>? tempNotes,
    bool clearInitialTransaction = false,
    bool clearErrorMessage = false,
    bool clearSuggestion = false,
    bool clearNewlyCreated = false,
    bool clearTempData = false,
    // --- Added flag to clear askCreateCategory ---
    bool clearAskCreateFlag = false,
  }) {
    return AddEditTransactionState(
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      initialTransaction: clearInitialTransaction
          ? null
          : (initialTransaction ?? this.initialTransaction),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage != null ? errorMessage() : this.errorMessage),
      suggestedCategory: clearSuggestion
          ? null
          : (suggestedCategory != null
              ? suggestedCategory()
              : this.suggestedCategory),
      newlyCreatedCategory: clearNewlyCreated
          ? null
          : (newlyCreatedCategory != null
              ? newlyCreatedCategory()
              : this.newlyCreatedCategory),
      // --- Assign flag ---
      askCreateCategory: clearAskCreateFlag
          ? false
          : (askCreateCategory ?? this.askCreateCategory),
      tempTitle: clearTempData ? null : (tempTitle ?? this.tempTitle),
      tempAmount: clearTempData ? null : (tempAmount ?? this.tempAmount),
      tempDate: clearTempData ? null : (tempDate ?? this.tempDate),
      tempAccountId:
          clearTempData ? null : (tempAccountId ?? this.tempAccountId),
      tempNotes: clearTempData
          ? null
          : (tempNotes != null ? tempNotes() : this.tempNotes),
    );
  }

  @override
  List<Object?> get props => [
        status, transactionType, initialTransaction, errorMessage,
        suggestedCategory, newlyCreatedCategory,
        // --- Add flag to props ---
        askCreateCategory,
        tempTitle, tempAmount, tempDate, tempAccountId, tempNotes,
      ];
}
