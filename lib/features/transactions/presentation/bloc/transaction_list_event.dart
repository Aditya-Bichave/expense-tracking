// lib/features/transactions/presentation/bloc/transaction_list_event.dart
part of 'transaction_list_bloc.dart';

abstract class TransactionListEvent extends Equatable {
  const TransactionListEvent();
  @override
  List<Object?> get props => [];
}

// Load initial or refresh all transactions based on current filters/sort
class LoadTransactions extends TransactionListEvent {
  final bool forceReload;
  // --- ADDED: Allow passing initial filters ---
  final Map<String, dynamic>? incomingFilters;
  // --- END ADD ---
  const LoadTransactions({this.forceReload = false, this.incomingFilters});
  @override
  List<Object?> get props => [forceReload, incomingFilters];
}

// Update filters and reload
class FilterChanged extends TransactionListEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final String? accountId;
  final TransactionType? transactionType;
  // Note: Search is handled by SearchChanged

  const FilterChanged({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
    this.transactionType,
  });

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    categoryId,
    accountId,
    transactionType,
  ];
}

// Update sort order and reload
class SortChanged extends TransactionListEvent {
  final TransactionSortBy sortBy;
  final SortDirection sortDirection;

  const SortChanged({required this.sortBy, required this.sortDirection});

  @override
  List<Object?> get props => [sortBy, sortDirection];
}

// Update search term and reload
class SearchChanged extends TransactionListEvent {
  final String? searchTerm;
  const SearchChanged({this.searchTerm});
  @override
  List<Object?> get props => [searchTerm];
}

// Toggle batch edit mode
class ToggleBatchEdit extends TransactionListEvent {
  const ToggleBatchEdit();
}

// Toggle between list and calendar views
class ToggleCalendarView extends TransactionListEvent {
  const ToggleCalendarView();
}

// Calendar interactions
class CalendarDaySelected extends TransactionListEvent {
  final DateTime selectedDay;
  final DateTime focusedDay;
  const CalendarDaySelected({
    required this.selectedDay,
    required this.focusedDay,
  });
  @override
  List<Object?> get props => [selectedDay, focusedDay];
}

class CalendarFormatChanged extends TransactionListEvent {
  final CalendarFormat format;
  const CalendarFormatChanged(this.format);
  @override
  List<Object?> get props => [format];
}

class CalendarPageChanged extends TransactionListEvent {
  final DateTime focusedDay;
  const CalendarPageChanged(this.focusedDay);
  @override
  List<Object?> get props => [focusedDay];
}

// Select/deselect a transaction in batch mode
class SelectTransaction extends TransactionListEvent {
  final String transactionId;
  const SelectTransaction(this.transactionId);
  @override
  List<Object> get props => [transactionId];
}

// Apply category to selected batch items
class ApplyBatchCategory extends TransactionListEvent {
  final String categoryId;
  const ApplyBatchCategory(this.categoryId);
  @override
  List<Object> get props => [categoryId];
}

// Delete a single transaction (requested from UI, e.g., swipe)
class DeleteTransaction extends TransactionListEvent {
  final TransactionEntity transaction; // Pass full entity to know type
  const DeleteTransaction(this.transaction);
  @override
  List<Object> get props => [transaction];
}

// User manually categorized/confirmed a transaction (for learning)
class UserCategorizedTransaction extends TransactionListEvent {
  final String transactionId;
  final TransactionType transactionType;
  final Category selectedCategory; // Use unified Category
  final TransactionMatchData matchData; // Data used for learning rule

  const UserCategorizedTransaction({
    required this.transactionId,
    required this.transactionType,
    required this.selectedCategory,
    required this.matchData,
  });

  @override
  List<Object?> get props => [
    transactionId,
    transactionType,
    selectedCategory,
    matchData,
  ];
}

// Internal event for reactive updates from data changes
class _DataChanged extends TransactionListEvent {
  const _DataChanged();
}

// --- ADDED: Reset State Event ---
class ResetState extends TransactionListEvent {
  const ResetState();
}

// --- END ADDED ---
