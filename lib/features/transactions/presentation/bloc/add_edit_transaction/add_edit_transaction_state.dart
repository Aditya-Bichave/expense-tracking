part of 'add_edit_transaction_bloc.dart';

// Status for the entire Add/Edit process
enum AddEditStatus {
  initial, // Before initialization
  ready, // Ready for user input or editing
  loading, // Generic loading (e.g., fetching suggestion, preparing navigation)
  suggestingCategory, // Suggestion found, waiting for user action
  navigatingToCreateCategory, // State indicating navigation is happening
  saving, // Saving the transaction to the database
  success, // Save completed successfully
  error // An error occurred
}

class AddEditTransactionState extends Equatable {
  final AddEditStatus status;
  final TransactionType transactionType;
  final TransactionEntity? initialTransaction;
  final String? errorMessage;
  final Category? suggestedCategory;
  final Category? newlyCreatedCategory;
  // --- ADDED Flag ---
  final bool askCreateCategory; // Flag to trigger the "Create/Select" dialog

  // Store form data temporarily
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
    this.askCreateCategory = false, // Initialize flag
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
    bool? askCreateCategory, // Add flag to copyWith
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
  }) {
    // If status is changing *away* from suggesting or navigating, reset the askCreate flag
    final bool shouldResetAskFlag = (status != null &&
        status != AddEditStatus.suggestingCategory &&
        status != AddEditStatus.navigatingToCreateCategory &&
        status != AddEditStatus.ready);

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
      askCreateCategory: shouldResetAskFlag
          ? false
          : (askCreateCategory ?? this.askCreateCategory), // Assign flag
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
        status,
        transactionType,
        initialTransaction,
        errorMessage,
        suggestedCategory,
        newlyCreatedCategory,
        askCreateCategory, // Add flag to props
        tempTitle,
        tempAmount,
        tempDate,
        tempAccountId,
        tempNotes,
      ];
}
