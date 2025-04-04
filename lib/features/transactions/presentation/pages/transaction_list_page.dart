// lib/features/transactions/presentation/pages/transaction_list_page.dart
// ignore_for_file: unused_element

import 'dart:async'; // For Timer (debounce)
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart'; // The intended Category entity
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_filter_dialog.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_sort_sheet.dart';
// Import the new decomposed widgets
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_header.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_calendar_view.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/foundation.dart' hide Category; // For listEquals
import 'package:flutter/material.dart'; // Hide the conflicting Category
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:table_calendar/table_calendar.dart'; // Needed for orElse fallback

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

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
  List<TransactionEntity> _selectedDayTransactions = [];
  List<TransactionEntity> _currentTransactionsForCalendar = [];
  StreamSubscription? _blocSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _selectedDay =
        DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);

    _setupInitialCalendarData();
    _listenToBlocChanges();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _blocSubscription?.cancel();
    super.dispose();
  }

  void _listenToBlocChanges() {
    _blocSubscription =
        context.read<TransactionListBloc>().stream.listen((state) {
      if (state.status == ListStatus.success && mounted) {
        if (!listEquals(_currentTransactionsForCalendar, state.transactions)) {
          log.fine(
              "[TxnListPage] BLoC state updated, refreshing calendar data cache.");
          setState(() {
            _currentTransactionsForCalendar = state.transactions;
            _updateSelectedDayTransactions();
          });
        }
      } else if (state.status != ListStatus.success &&
          mounted &&
          _currentTransactionsForCalendar.isNotEmpty) {
        log.fine(
            "[TxnListPage] BLoC state not success, clearing calendar data cache.");
        setState(() {
          _currentTransactionsForCalendar = [];
          _selectedDayTransactions = [];
        });
      }
    });
  }

  void _setupInitialCalendarData() {
    final bloc = context.read<TransactionListBloc>();
    if (bloc.state.status == ListStatus.initial) {
      bloc.add(const LoadTransactions()); // Trigger load if initial
    } else if (bloc.state.status == ListStatus.success) {
      _currentTransactionsForCalendar = bloc.state.transactions;
      _updateSelectedDayTransactions();
    }
  }

  // --- Interaction Handlers ---
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final searchTerm = _searchController.text.trim();
        log.fine("[TxnListPage] Search term changed: '$searchTerm'");
        context.read<TransactionListBloc>().add(
            SearchChanged(searchTerm: searchTerm.isEmpty ? null : searchTerm));
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context
        .read<TransactionListBloc>()
        .add(const SearchChanged(searchTerm: null));
  }

  void _navigateToDetailOrEdit(
      BuildContext context, TransactionEntity transaction) {
    log.info(
        "[TxnListPage] _navigateToDetailOrEdit called for ${transaction.type.name} ID: ${transaction.id}");
    const String routeName = RouteNames.editTransaction;
    final Map<String, String> params = {
      RouteNames.paramTransactionId: transaction.id
    };
    final dynamic extraData = transaction.originalEntity;

    if (extraData == null) {
      log.severe(
          "[TxnListPage] CRITICAL: originalEntity is null for transaction ID ${transaction.id}. Cannot navigate.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error preparing navigation data."),
          backgroundColor: Colors.red));
      return;
    }
    log.info("[TxnListPage] Attempting navigation via pushNamed:");
    log.info("  Route Name: $routeName");
    log.info("  Path Params: $params");
    log.info("  Extra Data Type: ${extraData?.runtimeType}");
    try {
      context.pushNamed(routeName, pathParameters: params, extra: extraData);
      log.info("[TxnListPage] pushNamed executed.");
    } catch (e, s) {
      log.severe("[TxnListPage] Error executing pushNamed: $e\n$s");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error navigating to edit screen: $e"),
          backgroundColor: Colors.red));
    }
  }

  void _handleChangeCategoryRequest(
      BuildContext context, TransactionEntity transaction) async {
    log.info(
        "[TxnListPage] Change category requested for item ID: ${transaction.id}");
    final categoryType = transaction.type == TransactionType.expense
        ? CategoryTypeFilter.expense
        : CategoryTypeFilter.income;
    final Category? selectedCategory =
        await showCategoryPicker(context, categoryType);

    if (selectedCategory != null && context.mounted) {
      log.info(
          "[TxnListPage] Category '${selectedCategory.name}' selected from picker.");
      final matchData = TransactionMatchData(
          description: transaction.title, merchantId: null);
      context.read<TransactionListBloc>().add(UserCategorizedTransaction(
          transactionId: transaction.id,
          transactionType: transaction.type,
          selectedCategory: selectedCategory,
          matchData: matchData));
    } else {
      log.info("[TxnListPage] Category picker dismissed without selection.");
    }
  }

  Future<bool> _confirmDeletion(
      BuildContext context, TransactionEntity transaction) async {
    return await AppDialogs.showConfirmation(
          context,
          title: "Confirm Deletion",
          content:
              'Are you sure you want to delete this ${transaction.type.name}:\n"${transaction.title}"?',
          confirmText: "Delete",
          confirmColor: Theme.of(context).colorScheme.error,
        ) ??
        false;
  }

  void _showFilterDialog(
      BuildContext context, TransactionListState currentState) async {
    log.info("[TxnListPage] Showing filter dialog.");
    final getCategoriesUseCase = sl<GetCategoriesUseCase>();
    final categoriesResult = await getCategoriesUseCase(const NoParams());
    List<Category> categories = [];
    if (categoriesResult.isRight()) {
      categories = categoriesResult.getOrElse(() => []);
    } else {
      log.warning("[TxnListPage] Failed to load categories for filter dialog.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Could not load categories for filtering.")));
      }
      return;
    }
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<AccountListBloc>(context),
          child: TransactionFilterDialog(
            availableCategories: categories,
            initialStartDate: currentState.startDate,
            initialEndDate: currentState.endDate,
            initialTransactionType: currentState.transactionType,
            initialAccountId: currentState.accountId,
            initialCategoryId: currentState.categoryId,
            onApplyFilter: (startDate, endDate, type, accountId, categoryId) {
              context.read<TransactionListBloc>().add(FilterChanged(
                  startDate: startDate,
                  endDate: endDate,
                  transactionType: type,
                  accountId: accountId,
                  categoryId: categoryId));
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
      BuildContext context, TransactionListState currentState) {
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
                  SortChanged(sortBy: sortBy, sortDirection: sortDirection));
            },
          );
        });
  }

  // --- Calendar Specific Logic ---
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalizedSelectedDay =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    log.fine("[TxnListPage] Calendar day selected: $normalizedSelectedDay");
    if (!isSameDay(_selectedDay, normalizedSelectedDay)) {
      setState(() {
        _selectedDay = normalizedSelectedDay;
        _focusedDay = focusedDay;
        _updateSelectedDayTransactions();
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
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  List<TransactionEntity> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _currentTransactionsForCalendar.where((txn) {
      final normalizedTxnDate =
          DateTime(txn.date.year, txn.date.month, txn.date.day);
      return isSameDay(normalizedTxnDate, normalizedDay);
    }).toList();
  }

  void _updateSelectedDayTransactions() {
    if (_selectedDay != null && mounted) {
      setState(() {
        _selectedDayTransactions = _getEventsForDay(_selectedDay!);
      });
    } else if (mounted) {
      setState(() {
        _selectedDayTransactions = [];
      });
    }
    log.fine(
        "[TxnListPage] Updated selected day transactions for $_selectedDay. Count: ${_selectedDayTransactions.length}");
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;

    return Scaffold(
      body: Column(
        children: [
          // Use the extracted header widget
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
                    ..showSnackBar(SnackBar(
                        content: Text("Error: ${state.errorMessage!}"),
                        backgroundColor: theme.colorScheme.error));
                }
              },
              builder: (context, state) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<TransactionListBloc>()
                        .add(const LoadTransactions(forceReload: true));
                    await context.read<TransactionListBloc>().stream.firstWhere(
                        (s) =>
                            s.status != ListStatus.loading &&
                            s.status != ListStatus.reloading);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _showCalendarView
                        ? KeyedSubtree(
                            key: const ValueKey('calendar_view'),
                            // Use the extracted calendar view widget
                            child: TransactionCalendarView(
                              state: state,
                              settings: settings,
                              calendarFormat: _calendarFormat,
                              focusedDay: _focusedDay,
                              selectedDay: _selectedDay,
                              selectedDayTransactions: _selectedDayTransactions,
                              currentTransactionsForCalendar:
                                  _currentTransactionsForCalendar,
                              getEventsForDay: _getEventsForDay,
                              onDaySelected: _onDaySelected,
                              onFormatChanged: _onFormatChanged,
                              onPageChanged: _onPageChanged,
                              navigateToDetailOrEdit: _navigateToDetailOrEdit,
                            ),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('list_view'),
                            // Use the extracted list view widget
                            child: TransactionListView(
                              state: state,
                              settings: settings,
                              navigateToDetailOrEdit: _navigateToDetailOrEdit,
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
          final bool showFab = state.isInBatchEditMode && !_showCalendarView;
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
                          "[TxnListPage] Batch categorize button pressed.");
                      final type = _getDominantTransactionType(state) ??
                          TransactionType.expense;
                      final Category? selectedCategory =
                          await showCategoryPicker(
                              context,
                              type == TransactionType.expense
                                  ? CategoryTypeFilter.expense
                                  : CategoryTypeFilter.income);
                      if (selectedCategory != null &&
                          selectedCategory.id != Category.uncategorized.id &&
                          context.mounted) {
                        context
                            .read<TransactionListBloc>()
                            .add(ApplyBatchCategory(selectedCategory.id));
                      } else if (selectedCategory?.id ==
                              Category.uncategorized.id &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Please select a specific category.")));
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

  // Helper to determine dominant type remains the same
  TransactionType? _getDominantTransactionType(TransactionListState state) {
    if (state.selectedTransactionIds.isEmpty) return null;
    TransactionType? type;
    for (final id in state.selectedTransactionIds) {
      final txn = state.transactions.firstWhere((t) => t.id == id, orElse: () {
        log.severe(
            "[TxnListPage] CRITICAL: Selected ID $id not found in state during dominant type check!");
        return TransactionEntity.fromExpense(Expense(
          id: 'error_$id', // Make ID unique for debugging
          title: 'Error: Not Found',
          amount: 0,
          date: DateTime.now(),
          accountId: 'error_account',
        ));
      });
      if (txn.accountId == 'error_account') continue;

      if (type == null) {
        type = txn.type;
      } else if (type != txn.type) {
        return null;
      }
    }
    return type;
  }
}

// String capitalization extension remains the same
extension StringCapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
