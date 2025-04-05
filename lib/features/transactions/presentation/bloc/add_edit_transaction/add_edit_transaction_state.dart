// lib/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_state.dart
part of 'add_edit_transaction_bloc.dart';

// Keep AddEditStatus enum
enum AddEditStatus {
  initial,
  ready, // Form is ready for input or display
  loading, // General loading (e.g., during auto-categorization)
  suggestingCategory, // Suggestion is ready to be shown
  askingCreateCategory, // Prompting user to create or select existing
  navigatingToCreateCategory, // In the process of navigating
  saving, // Actively saving the transaction
  success, // Save successful
  error // An error occurred
}

class AddEditTransactionState extends Equatable {
  final AddEditStatus status;
  final TransactionType transactionType;
  final TransactionEntity? initialTransaction;
  final String? errorMessage;
  final Category? suggestedCategory;
  final Category? newlyCreatedCategory; // Category just created via navigation

  // REMOVED askCreateCategory flag

  // Keep temporary fields for form state persistence during async ops
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
    // REMOVED askCreateCategory from constructor
    this.tempTitle,
    this.tempAmount,
    this.tempDate,
    this.tempAccountId,
    this.tempNotes,
  });

  bool get isEditing => initialTransaction != null;
  // Effective category considers newly created one first, then initial
  Category? get effectiveCategory =>
      newlyCreatedCategory ?? initialTransaction?.category;

  AddEditTransactionState copyWith({
    AddEditStatus? status,
    TransactionType? transactionType,
    TransactionEntity? initialTransaction,
    ValueGetter<String?>? errorMessage,
    ValueGetter<Category?>? suggestedCategory,
    ValueGetter<Category?>? newlyCreatedCategory,
    // REMOVED askCreateCategory parameter
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
    // REMOVED clearAskCreateFlag parameter
  }) {
    // If status is changing, clear related temporary states
    final bool shouldClearSuggestion = clearSuggestion ||
        (status != null && status != AddEditStatus.suggestingCategory);
    final bool shouldClearNewlyCreated = clearNewlyCreated ||
        (status != null &&
            status != AddEditStatus.ready &&
            status !=
                AddEditStatus
                    .saving); // Clear if status changes away from ready/saving after creation
    final bool shouldClearError =
        clearErrorMessage || (status != null && status != AddEditStatus.error);

    return AddEditTransactionState(
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      initialTransaction: clearInitialTransaction
          ? null
          : (initialTransaction ?? this.initialTransaction),
      errorMessage: shouldClearError
          ? null
          : (errorMessage != null ? errorMessage() : this.errorMessage),
      suggestedCategory: shouldClearSuggestion
          ? null
          : (suggestedCategory != null
              ? suggestedCategory()
              : this.suggestedCategory),
      newlyCreatedCategory: shouldClearNewlyCreated
          ? null
          : (newlyCreatedCategory != null
              ? newlyCreatedCategory()
              : this.newlyCreatedCategory),
      // REMOVED askCreateCategory assignment
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
        // REMOVED askCreateCategory from props
        tempTitle, tempAmount, tempDate, tempAccountId, tempNotes,
      ];
}
