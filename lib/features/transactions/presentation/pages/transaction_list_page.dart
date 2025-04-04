// ignore_for_file: unused_element

import 'dart:async'; // For Timer (debounce)
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/widgets/transaction_list_item.dart';
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
import 'package:expense_tracker/main.dart';
import 'package:flutter/foundation.dart' hide Category; // For listEquals
import 'package:flutter/material.dart'; // Hide the conflicting Category
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart'; // Needed for orElse fallback

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

  // --- Keep initState, dispose, _listenToBlocChanges, _setupInitialCalendarData as they are ---
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

  // --- UPDATED NAVIGATION to use new route name ---
  void _navigateToDetailOrEdit(
      BuildContext context, TransactionEntity transaction) {
    log.info(
        "[TxnListPage] _navigateToDetailOrEdit called for ${transaction.type.name} ID: ${transaction.id}");

    // Use the unified edit route name
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
        backgroundColor: Colors.red,
      ));
      return;
    }

    log.info("[TxnListPage] Attempting navigation via pushNamed:");
    log.info("  Route Name: $routeName");
    log.info("  Path Params: $params");
    log.info("  Extra Data Type: ${extraData?.runtimeType}");

    try {
      context.pushNamed(
        routeName,
        pathParameters: params,
        extra: extraData,
      );
      log.info("[TxnListPage] pushNamed executed.");
    } catch (e, s) {
      log.severe("[TxnListPage] Error executing pushNamed: $e\n$s");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error navigating to edit screen: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }
  // --- END UPDATED ---

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

  // --- Keep Dialog/Sheet Show Methods as they are ---
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

  // --- Keep Calendar Specific Logic as it is ---
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

  // --- Keep Build Methods as they are (mostly) ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;

    return Scaffold(
      body: Column(
        children: [
          _buildHeaderControls(context, theme),
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
                            child: _buildCalendarView(context, state, settings),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('list_view'),
                            child:
                                _buildTransactionList(context, state, settings),
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
                    log.info("[TxnListPage] Batch categorize button pressed.");
                    final type = _getDominantTransactionType(state) ??
                        TransactionType.expense;
                    final Category? selectedCategory = await showCategoryPicker(
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please select a specific category.")));
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
      }),
    );
  }

  Widget _buildHeaderControls(BuildContext context, ThemeData theme) {
    // ... keep this implementation as is ...
    return BlocBuilder<TransactionListBloc, TransactionListState>(
        builder: (context, state) {
      final isInBatchMode = state.isInBatchEditMode;
      final bool hasSearchTerm =
          state.searchTerm != null && state.searchTerm!.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search title, category, amount...",
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: theme.colorScheme.primary)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                isDense: true,
                suffixIcon: hasSearchTerm
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: "Clear Search",
                        onPressed: _clearSearch)
                    : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.filter_list_rounded,
                          size: 18,
                          color: state.filtersApplied
                              ? theme.colorScheme.primary
                              : null),
                      label: Text("Filter",
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: state.filtersApplied
                                  ? theme.colorScheme.primary
                                  : null)),
                      onPressed: () => _showFilterDialog(context, state),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.sort_rounded, size: 18),
                      label: Text("Sort", style: theme.textTheme.labelMedium),
                      onPressed: () => _showSortDialog(context, state),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          _showCalendarView
                              ? Icons.view_list_rounded
                              : Icons.calendar_today_rounded,
                          size: 20),
                      tooltip:
                          _showCalendarView ? "List View" : "Calendar View",
                      onPressed: () => setState(
                          () => _showCalendarView = !_showCalendarView),
                    ),
                    IconButton(
                      icon: Icon(
                          isInBatchMode
                              ? Icons.cancel_outlined
                              : Icons.select_all_rounded,
                          size: 20),
                      tooltip: isInBatchMode
                          ? "Cancel Selection"
                          : "Select Multiple",
                      color: isInBatchMode ? theme.colorScheme.primary : null,
                      onPressed: () => context
                          .read<TransactionListBloc>()
                          .add(const ToggleBatchEdit()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCalendarView(BuildContext context, TransactionListState state,
      SettingsState settings) {
    // ... keep this implementation as is ...
    final theme = Theme.of(context);

    if (state.status == ListStatus.loading &&
        _currentTransactionsForCalendar.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ListStatus.error &&
        _currentTransactionsForCalendar.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                  "Error loading data for calendar: ${state.errorMessage}",
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center)));
    }

    return Column(
      children: [
        TableCalendar<TransactionEntity>(
          firstDay: DateTime.utc(2010, 1, 1),
          lastDay: DateTime.utc(2040, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.twoWeeks: '2 Weeks',
            CalendarFormat.week: 'Week',
          },
          eventLoader: (day) => _getEventsForDay(day),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary, shape: BoxShape.circle),
            markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary, shape: BoxShape.circle),
            outsideDaysVisible: false,
            markersMaxCount: 1,
            markerSize: 5.0,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            weekendTextStyle:
                TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
            todayTextStyle: TextStyle(color: theme.colorScheme.primary),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium!,
            formatButtonTextStyle:
                TextStyle(color: theme.colorScheme.primary, fontSize: 12),
            formatButtonDecoration: BoxDecoration(
              border:
                  Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12.0),
            ),
            leftChevronIcon:
                Icon(Icons.chevron_left, color: theme.colorScheme.primary),
            rightChevronIcon:
                Icon(Icons.chevron_right, color: theme.colorScheme.primary),
          ),
          onDaySelected: _onDaySelected,
          onFormatChanged: _onFormatChanged,
          onPageChanged: _onPageChanged,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: _buildSelectedDayTransactionList(context, settings),
        ),
      ],
    );
  }

  Widget _buildSelectedDayTransactionList(
      BuildContext context, SettingsState settings) {
    // ... keep this implementation as is ...
    final theme = Theme.of(context);
    if (_selectedDayTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
              "No transactions on ${DateFormatter.formatDate(_selectedDay ?? _focusedDay)}.",
              style: theme.textTheme.bodyMedium),
        ),
      );
    }
    return ListView.builder(
      key: ValueKey(_selectedDay),
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
      itemCount: _selectedDayTransactions.length,
      itemBuilder: (ctx, index) {
        final transaction = _selectedDayTransactions[index];
        return TransactionListItem(
          transaction: transaction,
          currencySymbol: settings.currencySymbol,
          onTap: () => _navigateToDetailOrEdit(context, transaction),
        )
            .animate()
            .fadeIn(delay: (50 * index).ms, duration: 300.ms)
            .slideX(begin: 0.2, curve: Curves.easeOutCubic);
      },
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildTransactionList(BuildContext context, TransactionListState state,
      SettingsState settings) {
    // ... keep this implementation as is (using the version WITHOUT Dismissible) ...
    final theme = Theme.of(context);

    if (state.status == ListStatus.loading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ListStatus.error && state.transactions.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                  "Error: ${state.errorMessage ?? 'Failed to load transactions'}",
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center)));
    }
    if (state.transactions.isEmpty &&
        state.status != ListStatus.loading &&
        state.status != ListStatus.reloading) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 60,
                        color: theme.colorScheme.secondary.withOpacity(0.7)),
                    const SizedBox(height: 16),
                    Text(
                        state.filtersApplied
                            ? "No transactions match filters"
                            : "No transactions recorded yet",
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      state.filtersApplied
                          ? "Try adjusting or clearing the filters."
                          : "Tap the '+' button to add your first expense or income.",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ])));
    }

    return ListView.builder(
      padding:
          const EdgeInsets.only(top: 0, bottom: 80), // Ensure padding for FAB
      itemCount: state.transactions.length,
      itemBuilder: (ctx, index) {
        final transaction = state.transactions[index];
        final isSelected =
            state.selectedTransactionIds.contains(transaction.id);

        return Container(
          // Use Container for background color
          key: ValueKey(
              "${transaction.id}_list_item_${isSelected}"), // Unique key for item
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          child: TransactionListItem(
            transaction: transaction,
            currencySymbol: settings.currencySymbol,
            onTap: () {
              // Assign tap logic directly here
              if (state.isInBatchEditMode) {
                log.fine(
                    "[TxnListPage] Item tapped in batch mode. Toggling selection for ${transaction.id}.");
                context
                    .read<TransactionListBloc>()
                    .add(SelectTransaction(transaction.id));
              } else {
                log.fine(
                    "[TxnListPage] Item tapped in normal mode. Navigating to edit for ${transaction.id}.");
                _navigateToDetailOrEdit(
                    context, transaction); // Navigate on normal tap
              }
            },
          ),
        ).animate().fadeIn(delay: (20 * index).ms).slideY(begin: 0.1);
      },
    );
  }

  TransactionType? _getDominantTransactionType(TransactionListState state) {
    // ... keep this implementation as is ...
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

// --- Keep StringCapExtension as is ---
extension StringCapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
