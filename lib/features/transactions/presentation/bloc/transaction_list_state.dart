part of 'transaction_list_bloc.dart';

// --- Status Enums (Can be defined here or in core) ---
enum ListStatus { initial, loading, reloading, success, error }

// --- Main State ---
class TransactionListState extends Equatable {
  final ListStatus status;
  final List<TransactionEntity> transactions;
  // Filters
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final String? accountId;
  final TransactionType? transactionType;
  final String? searchTerm;
  // Sorting
  final TransactionSortBy sortBy;
  final SortDirection sortDirection;
  // Batch Edit
  final bool isInBatchEditMode;
  final Set<String> selectedTransactionIds;
  // Error
  final String? errorMessage;
  // Transient error specifically for delete failures
  final String? deleteError;
  final bool isCalendarViewVisible;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;

  TransactionListState({
    this.status = ListStatus.initial,
    this.transactions = const [],
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
    this.transactionType,
    this.searchTerm,
    this.sortBy = TransactionSortBy.date,
    this.sortDirection = SortDirection.descending,
    this.isInBatchEditMode = false,
    this.selectedTransactionIds = const {},
    this.errorMessage,
    this.deleteError,
    this.isCalendarViewVisible = false,
    DateTime? focusedDay,
    DateTime? selectedDay,
    this.calendarFormat = CalendarFormat.month,
  }) : focusedDay = focusedDay ?? DateTime.now(),
       selectedDay = selectedDay ?? DateTime.now();

  // Helper to check if filters are applied (excluding search)
  bool get filtersApplied =>
      startDate != null ||
      endDate != null ||
      categoryId != null ||
      accountId != null ||
      transactionType != null;

  TransactionListState copyWith({
    ListStatus? status,
    List<TransactionEntity>? transactions,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
    TransactionType? transactionType,
    String? searchTerm,
    TransactionSortBy? sortBy,
    SortDirection? sortDirection,
    bool? isInBatchEditMode,
    Set<String>? selectedTransactionIds,
    String? errorMessage,
    String? deleteError,
    bool? isCalendarViewVisible,
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarFormat? calendarFormat,
    // Flags to clear nullable fields
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearCategoryId = false,
    bool clearAccountId = false,
    bool clearTransactionType = false,
    bool clearSearchTerm = false,
    bool clearErrorMessage = false,
    bool clearDeleteError = false,
  }) {
    return TransactionListState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      searchTerm: clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      isInBatchEditMode: isInBatchEditMode ?? this.isInBatchEditMode,
      selectedTransactionIds:
          selectedTransactionIds ?? this.selectedTransactionIds,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      deleteError: clearDeleteError ? null : (deleteError ?? this.deleteError),
      isCalendarViewVisible:
          isCalendarViewVisible ?? this.isCalendarViewVisible,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      calendarFormat: calendarFormat ?? this.calendarFormat,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    startDate,
    endDate,
    categoryId,
    accountId,
    transactionType,
    searchTerm,
    sortBy,
    sortDirection,
    isInBatchEditMode,
    selectedTransactionIds,
    errorMessage,
    deleteError,
    isCalendarViewVisible,
    focusedDay,
    selectedDay,
    calendarFormat,
  ];
}
