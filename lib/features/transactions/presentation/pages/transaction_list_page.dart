// lib/features/transactions/presentation/pages/transaction_list_page.dart
import 'dart:async'; // For Timer (debounce)
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart'; // The intended Category entity
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_dialog.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_sort_sheet.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_header.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_calendar_view.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart'; // Hide the conflicting Category
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';

class TransactionListPage extends StatefulWidget {
  // --- ADDED: Accept optional initial filters ---
  final Map<String, dynamic>? initialFilters;
  // --- END ADD ---
  const TransactionListPage({super.key, this.initialFilters});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showCalendarView = false;
  Timer? _debounce;

  // Calendar state
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Optimized lookup cache
  Map<DateTime, List<TransactionEntity>> _transactionsByDay = {};
  List<TransactionEntity>? _lastTransactions;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );

    // --- MODIFIED: Apply initial filters if provided ---
    if (widget.initialFilters != null && widget.initialFilters!.isNotEmpty) {
      log.info(
        "[TxnListPage] Applying initial filters from route: ${widget.initialFilters}",
      );
      // Dispatch event to bloc to apply filters and load
      context.read<TransactionListBloc>().add(
        LoadTransactions(
          forceReload: true,
          incomingFilters: widget.initialFilters,
        ),
      );
    } else {
      // Load normally if no initial filters
      _setupInitialCalendarData();
    }
    // --- END MODIFICATION ---
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _setupInitialCalendarData() {
    final bloc = context.read<TransactionListBloc>();
    if (bloc.state.status == ListStatus.initial) {
      bloc.add(const LoadTransactions()); // Trigger load if initial
    }
  }

  // --- Interaction Handlers (Keep as is) ---
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final searchTerm = _searchController.text.trim();
        log.fine("[TxnListPage] Search term changed: '$searchTerm'");
        context.read<TransactionListBloc>().add(
          SearchChanged(searchTerm: searchTerm.isEmpty ? null : searchTerm),
        );
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    // Bloc listener will handle the reload via SearchChanged event
  }

  void _navigateToDetailOrEdit(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    log.info(
      "[TxnListPage] _navigateToDetailOrEdit called for ${transaction.type.name} ID: ${transaction.id}",
    );
    const String routeName =
        RouteNames.editTransaction; // Navigate to Edit by default
    final Map<String, String> params = {
      RouteNames.paramTransactionId: transaction.id,
    };
    log.info("[TxnListPage] Attempting navigation via pushNamed:");
    log.info("  Route Name: $routeName");
    log.info("  Path Params: $params");
    log.info("  Extra Data Type: ${transaction.runtimeType}");
    try {
      context.pushNamed(routeName, pathParameters: params, extra: transaction);
      log.info("[TxnListPage] pushNamed executed.");
    } catch (e, s) {
      log.severe("[TxnListPage] Error executing pushNamed: $e\n$s");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error navigating to edit screen: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleChangeCategoryRequest(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    log.info(
      "[TxnListPage] Change category requested for item ID: ${transaction.id}",
    );
    final categoryType = transaction.type == TransactionType.expense
        ? CategoryTypeFilter.expense
        : CategoryTypeFilter.income;
    final categoryState = context.read<CategoryManagementBloc>().state;
    final categories = categoryType == CategoryTypeFilter.expense
        ? categoryState.allExpenseCategories
        : categoryState.allIncomeCategories;
    final Category? selectedCategory = await showCategoryPicker(
      context,
      categoryType,
      categories,
    );

    if (selectedCategory != null && context.mounted) {
      log.info(
        "[TxnListPage] Category '${selectedCategory.name}' selected from picker.",
      );
      // Prepare data for learning user history
      final matchData = TransactionMatchData(
        description: transaction.title,
        merchantId: transaction.merchantId,
      );
      context.read<TransactionListBloc>().add(
        UserCategorizedTransaction(
          transactionId: transaction.id,
          transactionType: transaction.type,
          selectedCategory: selectedCategory,
          matchData: matchData,
        ),
      );
    } else {
      log.info("[TxnListPage] Category picker dismissed without selection.");
    }
  }

  Future<bool> _confirmDeletion(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    return await AppDialogs.showConfirmation(
          context,
          title: "Confirm Deletion",
          content:
              'Are you sure you want to permanently delete this ${transaction.type.name}:\n"${transaction.title}"?',
          confirmText: "Delete",
          confirmColor: Theme.of(context).colorScheme.error,
        ) ??
        false; // Default to false if dialog is dismissed
  }

  void _showFilterDialog(
    BuildContext context,
    TransactionListState currentState,
  ) async {
    log.info("[TxnListPage] Showing filter dialog.");
    final getCategoriesUseCase =
        sl<GetCategoriesUseCase>(); // Assuming it's registered
    final categoriesResult = await getCategoriesUseCase(const NoParams());
    List<Category> categories = [];
    if (categoriesResult.isRight()) {
      categories = categoriesResult.getOrElse(() => []);
    } else {
      log.warning("[TxnListPage] Failed to load categories for filter dialog.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not load categories for filtering."),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          // Ensure AccountListBloc is available
          value: BlocProvider.of<AccountListBloc>(context),
          child: TransactionFilterDialog(
            availableCategories: categories, // Pass fetched categories
            initialStartDate: currentState.startDate,
            initialEndDate: currentState.endDate,
            initialTransactionType: currentState.transactionType,
            initialAccountId: currentState.accountId,
            initialCategoryId: currentState.categoryId,
            onApplyFilter: (startDate, endDate, type, accountId, categoryId) {
              context.read<TransactionListBloc>().add(
                FilterChanged(
                  startDate: startDate,
                  endDate: endDate,
                  transactionType: type,
                  accountId: accountId,
                  categoryId: categoryId,
                ),
              );
            },
            onClearFilter: () {
              context.read<TransactionListBloc>().add(const FilterChanged());
            },
          ),
        );
      },
    );
  }

  void _showSortDialog(
    BuildContext context,
    TransactionListState currentState,
  ) {
    log.info("[TxnListPage] Showing sort bottom sheet.");
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return TransactionSortSheet(
          currentSortBy: currentState.sortBy,
          currentSortDirection: currentState.sortDirection,
          onApplySort: (sortBy, sortDirection) {
            context.read<TransactionListBloc>().add(
              SortChanged(sortBy: sortBy, sortDirection: sortDirection),
            );
          },
        );
      },
    );
  }

  // --- Calendar Specific Logic ---
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalizedSelectedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    log.fine("[TxnListPage] Calendar day selected: $normalizedSelectedDay");
    if (!isSameDay(_selectedDay, normalizedSelectedDay)) {
      setState(() {
        _selectedDay = normalizedSelectedDay;
        _focusedDay = focusedDay; // Keep focusedDay in sync
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      log.fine("[TxnListPage] Calendar format changed to: $format");
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    log.fine("[TxnListPage] Calendar page changed, focused day: $focusedDay");
    _focusedDay = focusedDay;
  }

  void _updateTransactionsMap(List<TransactionEntity> transactions) {
    if (identical(transactions, _lastTransactions)) return;

    _transactionsByDay = {};
    for (final txn in transactions) {
      final date = DateTime(txn.date.year, txn.date.month, txn.date.day);
      if (!_transactionsByDay.containsKey(date)) {
        _transactionsByDay[date] = [];
      }
      _transactionsByDay[date]!.add(txn);
    }
    _lastTransactions = transactions;
  }

  List<TransactionEntity> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _transactionsByDay[normalizedDay] ?? [];
  }

  // --- Main Build Method (Keep as is) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final accountState = context.watch<AccountListBloc>().state;
    final accountNameMap = <String, String>{};
    if (accountState is AccountListLoaded) {
      for (final acc in accountState.items) {
        accountNameMap[acc.id] = acc.name;
      }
    }

    return Scaffold(
      body: Column(
        children: [
          TransactionListHeader(
            searchController: _searchController,
            onClearSearch: _clearSearch,
            onToggleCalendarView: () =>
                setState(() => _showCalendarView = !_showCalendarView),
            isCalendarViewShown: _showCalendarView,
            showFilterDialog: _showFilterDialog,
            showSortDialog: _showSortDialog,
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: BlocConsumer<TransactionListBloc, TransactionListState>(
              listener: (context, state) {
                if (state.status == ListStatus.error &&
                    state.errorMessage != null) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text("Error: ${state.errorMessage!}"),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                }
              },
              builder: (context, state) {
                _updateTransactionsMap(state.transactions);
                final selectedTransactions = _selectedDay == null
                    ? <TransactionEntity>[]
                    : _getEventsForDay(_selectedDay!);
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TransactionListBloc>().add(
                      const LoadTransactions(forceReload: true),
                    );
                    await context.read<TransactionListBloc>().stream.firstWhere(
                      (s) =>
                          s.status != ListStatus.loading &&
                          s.status != ListStatus.reloading,
                    );
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _showCalendarView
                        ? KeyedSubtree(
                            key: const ValueKey('calendar_view'),
                            child: TransactionCalendarView(
                              state: state,
                              settings: settings,
                              calendarFormat: _calendarFormat,
                              focusedDay: _focusedDay,
                              selectedDay: _selectedDay,
                              selectedDayTransactions: selectedTransactions,
                              currentTransactionsForCalendar:
                                  state.transactions,
                              getEventsForDay: _getEventsForDay,
                              onDaySelected: _onDaySelected,
                              onFormatChanged: _onFormatChanged,
                              onPageChanged: _onPageChanged,
                              navigateToDetailOrEdit: _navigateToDetailOrEdit,
                            ),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('list_view'),
                            child: TransactionListView(
                              state: state,
                              settings: settings,
                              accountNameMap: accountNameMap,
                              currencySymbol: settings.currencySymbol,
                              navigateToDetailOrEdit: _navigateToDetailOrEdit,
                              handleChangeCategoryRequest:
                                  _handleChangeCategoryRequest,
                              confirmDeletion: _confirmDeletion,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          BlocBuilder<TransactionListBloc, TransactionListState>(
            builder: (context, state) {
              final bool showFab =
                  state.isInBatchEditMode && !_showCalendarView;
              final int count = state.selectedTransactionIds.length;
              return AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: showFab ? 1.0 : 0.0,
                child: FloatingActionButton.extended(
                  key: const ValueKey('batch_fab'),
                  heroTag: 'transactions_batch_fab',
                  onPressed: count > 0
                      ? () async {
                          log.info(
                            "[TxnListPage] Batch categorize button pressed.",
                          );
                          final type =
                              _getDominantTransactionType(state) ??
                              TransactionType.expense;
                          final CategoryTypeFilter pickerType =
                              type == TransactionType.expense
                              ? CategoryTypeFilter.expense
                              : CategoryTypeFilter.income;
                          final catState = context
                              .read<CategoryManagementBloc>()
                              .state;
                          final list = pickerType == CategoryTypeFilter.expense
                              ? catState.allExpenseCategories
                              : catState.allIncomeCategories;
                          final Category? selectedCategory =
                              await showCategoryPicker(
                                context,
                                pickerType,
                                list,
                              );
                          if (selectedCategory != null &&
                              selectedCategory.id !=
                                  Category.uncategorized.id &&
                              context.mounted) {
                            context.read<TransactionListBloc>().add(
                              ApplyBatchCategory(selectedCategory.id),
                            );
                          } else if (selectedCategory?.id ==
                                  Category.uncategorized.id &&
                              context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please select a specific category.",
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  label: Text(count > 0 ? 'Categorize ($count)' : 'Categorize'),
                  icon: const Icon(Icons.category_rounded),
                  backgroundColor: count > 0
                      ? theme.colorScheme.secondaryContainer
                      : theme.disabledColor.withOpacity(0.1),
                  foregroundColor: count > 0
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.disabledColor,
                ),
              );
            },
          ),
    );
  }

  TransactionType? _getDominantTransactionType(TransactionListState state) {
    if (state.selectedTransactionIds.isEmpty) return null;
    TransactionType? type;
    for (final id in state.selectedTransactionIds) {
      final txn = state.transactions.firstWhereOrNull((t) => t.id == id);
      if (txn == null) {
        log.warning(
          "[TxnListPage] Selected ID $id not found in state during dominant type check.",
        );
        return null;
      }

      if (type == null) {
        type = txn.type;
      } else if (type != txn.type) {
        return null; // Mixed types selected
      }
    }
    return type;
  }
}

@visibleForTesting
TransactionType? getDominantTransactionTypeForTesting(
  TransactionListState state,
) => _TransactionListPageState()._getDominantTransactionType(state);
