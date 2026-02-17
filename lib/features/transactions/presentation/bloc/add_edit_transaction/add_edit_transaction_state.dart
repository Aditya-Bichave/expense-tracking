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
  error, // An error occurred
}

class AddEditTransactionState extends Equatable {
  final AddEditStatus status;
  final TransactionType transactionType;
  final String? transactionId; // ID of transaction being edited
  final Category? category; // Initial or selected category
  final String? errorMessage;
  final Category? suggestedCategory;
  final Category? newlyCreatedCategory; // Category just created via navigation

  // Keep temporary fields for form state persistence during async ops
  final String? tempTitle;
  final double? tempAmount;
  final DateTime? tempDate;
  final String? tempAccountId;
  final String? tempNotes;

  const AddEditTransactionState({
    this.status = AddEditStatus.initial,
    this.transactionType = TransactionType.expense,
    this.transactionId,
    this.category,
    this.errorMessage,
    this.suggestedCategory,
    this.newlyCreatedCategory,
    this.tempTitle,
    this.tempAmount,
    this.tempDate,
    this.tempAccountId,
    this.tempNotes,
  });

  bool get isEditing => transactionId != null;

  // Effective category considers newly created one first, then initial/selected
  Category? get effectiveCategory => newlyCreatedCategory ?? category;

  AddEditTransactionState copyWith({
    AddEditStatus? status,
    TransactionType? transactionType,
    String? transactionId,
    ValueGetter<Category?>? category,
    ValueGetter<String?>? errorMessage,
    ValueGetter<Category?>? suggestedCategory,
    ValueGetter<Category?>? newlyCreatedCategory,
    String? tempTitle,
    double? tempAmount,
    DateTime? tempDate,
    String? tempAccountId,
    ValueGetter<String?>? tempNotes,
    bool clearErrorMessage = false,
    bool clearSuggestion = false,
    bool clearNewlyCreated = false,
    bool clearTempData = false,
    bool clearCategory = false,
  }) {
    final bool shouldClearSuggestion =
        clearSuggestion ||
        (status != null && status != AddEditStatus.suggestingCategory);
    final bool shouldClearNewlyCreated =
        clearNewlyCreated ||
        (status != null &&
            status != AddEditStatus.ready &&
            status != AddEditStatus.saving);
    final bool shouldClearError =
        clearErrorMessage || (status != null && status != AddEditStatus.error);

    return AddEditTransactionState(
      status: status ?? this.status,
      transactionType: transactionType ?? this.transactionType,
      transactionId: transactionId ?? this.transactionId,
      category: clearCategory
          ? null
          : (category != null ? category() : this.category),
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
      tempTitle: clearTempData ? null : (tempTitle ?? this.tempTitle),
      tempAmount: clearTempData ? null : (tempAmount ?? this.tempAmount),
      tempDate: clearTempData ? null : (tempDate ?? this.tempDate),
      tempAccountId: clearTempData
          ? null
          : (tempAccountId ?? this.tempAccountId),
      tempNotes: clearTempData
          ? null
          : (tempNotes != null ? tempNotes() : this.tempNotes),
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactionType,
    transactionId,
    category,
    errorMessage,
    suggestedCategory,
    newlyCreatedCategory,
    tempTitle,
    tempAmount,
    tempDate,
    tempAccountId,
    tempNotes,
  ];
}
