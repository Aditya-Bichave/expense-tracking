import 'package:flutter/material.dart'; // Remove 'hide Category'
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
// *** FIX: Add prefix to our entity import ***
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'
    as entity;
import 'package:flutter/foundation.dart'; // For debugPrint

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  // Method to handle manual pull-to-refresh
  Future<void> _refreshExpenses(BuildContext context) async {
    debugPrint("[ExpenseListPage] _refreshExpenses called.");
    // Refresh this page's BLoC (and SummaryBloc will refresh via stream listener)
    try {
      context
          .read<ExpenseListBloc>()
          .add(const LoadExpenses(forceReload: true));
    } catch (e) {
      debugPrint("Error reading ExpenseListBloc for refresh: $e");
      return;
    }

    // Optionally wait for the state update if needed for UI feedback
    try {
      await context.read<ExpenseListBloc>().stream.firstWhere(
          (state) => state is ExpenseListLoaded || state is ExpenseListError,
          orElse: () => ExpenseListInitial() // Fallback
          );
      debugPrint("[ExpenseListPage] Refresh stream finished.");
    } catch (e) {
      debugPrint("Error waiting for refresh stream: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assuming SummaryBloc is provided globally or above this widget
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          // Filter button
          BlocBuilder<ExpenseListBloc, ExpenseListState>(
            builder: (context, state) {
              DateTime? currentStart;
              DateTime? currentEnd;
              String? currentCategory;
              if (state is ExpenseListLoaded) {
                currentStart = state.filterStartDate;
                currentEnd = state.filterEndDate;
                currentCategory = state.filterCategory;
              }
              return IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter Expenses',
                onPressed: () => _showFilterDialog(
                    context, currentStart, currentEnd, currentCategory),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshExpenses(context),
        child: Column(
          children: [
            // Summary Card automatically updates via its own stream listener
            const SummaryCard(),
            const Divider(height: 1),
            Expanded(
              child: BlocConsumer<ExpenseListBloc, ExpenseListState>(
                listener: (context, state) {
                  // Handle errors shown via SnackBar if needed
                  if (state is ExpenseListError) {
                    // Potentially show a snackbar for specific errors,
                    // but the builder already handles displaying an error UI.
                  }
                },
                builder: (context, state) {
                  debugPrint(
                      "[ExpenseListPage] Builder running for state: ${state.runtimeType}");
                  // Show loading only on initial load
                  if (state is ExpenseListLoading &&
                      state is! ExpenseListLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ExpenseListLoaded) {
                    if (state.expenses.isEmpty) {
                      // Display empty state
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.money_off,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No expenses found.',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (state.filterStartDate != null ||
                                state.filterEndDate != null ||
                                state.filterCategory != null)
                              ElevatedButton.icon(
                                // Option to clear filters
                                icon: const Icon(
                                  Icons.filter_alt_off_outlined,
                                  size: 18,
                                ),
                                label: const Text('Clear Filters'),
                                style: ElevatedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  // Use context.read inside callbacks
                                  context
                                      .read<ExpenseListBloc>()
                                      .add(const FilterExpenses());
                                  // SummaryBloc will react via stream
                                },
                              )
                            else
                              const Text(
                                // Prompt to add first expense
                                'Tap + to add your first expense!',
                                style: TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      );
                    }
                    // Display the list
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.expenses.length,
                      itemBuilder: (context, index) {
                        final expense = state.expenses[index];
                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red[700],
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text("Delete",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.delete_sweep_outlined,
                                    color: Colors.white),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            // Confirmation Dialog
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext ctx) => AlertDialog(
                                    title: const Text("Confirm Deletion"),
                                    content: Text(
                                        'Delete expense "${expense.title}"?'),
                                    actions: <Widget>[
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text("Cancel")),
                                      TextButton(
                                          style: TextButton.styleFrom(
                                              foregroundColor: Colors.red),
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text("Delete")),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (direction) {
                            // Dispatch delete event - Stream handles refreshes
                            context
                                .read<ExpenseListBloc>()
                                .add(DeleteExpenseRequested(expense.id));

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Expense "${expense.title}" deleted.'),
                              backgroundColor: Colors.orange,
                            ));
                          },
                          child: ExpenseCard(
                            expense: expense,
                            onTap: () {
                              // Navigate to edit page
                              context.pushNamed('edit_expense',
                                  pathParameters: {'id': expense.id},
                                  extra: expense);
                            },
                          ),
                        );
                      },
                    );
                  } else if (state is ExpenseListError) {
                    // Display error UI
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                                size: 50),
                            const SizedBox(height: 16),
                            Text('Error Loading Expenses:',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(state.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              onPressed: () => context // Use context.read
                                  .read<ExpenseListBloc>()
                                  .add(const LoadExpenses()),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  // Fallback for Initial state, show loading
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_expenses', // Ensure unique heroTag
        onPressed: () {
          context.pushNamed('add_expense');
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Filter Dialog Logic
  void _showFilterDialog(BuildContext context, DateTime? currentStart,
      DateTime? currentEnd, String? currentCategoryName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use the existing FilterDialogContent widget
        return FilterDialogContent(
            initialStartDate: currentStart,
            initialEndDate: currentEnd,
            initialCategory:
                currentCategoryName, // Pass the category NAME string
            onApplyFilter: (startDate, endDate, categoryName) {
              // Dispatch FilterExpenses event
              // SummaryBloc will react via stream listener if needed
              context.read<ExpenseListBloc>().add(FilterExpenses(
                    startDate: startDate,
                    endDate: endDate,
                    category: categoryName,
                  ));
              Navigator.of(dialogContext).pop(); // Close dialog
            },
            onClearFilter: () {
              // Dispatch FilterExpenses with null values
              // SummaryBloc will react via stream listener if needed
              context.read<ExpenseListBloc>().add(const FilterExpenses(
                    startDate: null,
                    endDate: null,
                    category: null,
                  ));
              Navigator.of(dialogContext).pop(); // Close dialog
            });
      },
    );
  }
} // END of ExpenseListPage class

// --- FilterDialogContent Widget ---
class FilterDialogContent extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialCategory; // Expects String
  final Function(DateTime?, DateTime?, String?) onApplyFilter; // Expects String
  final VoidCallback onClearFilter;

  const FilterDialogContent({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialCategory,
    required this.onApplyFilter,
    required this.onClearFilter,
  }) : super(key: key);

  @override
  _FilterDialogContentState createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<FilterDialogContent> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategory; // Stores String
  // *** FIX: Use prefix for our entity and explicitly type map ***
  final List<String> _categoryNames = entity.PredefinedCategory.values
      .map<String>((e) => // Explicitly map to String
          entity.Category.fromPredefined(e).name) // Use prefix
      .toList();

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.initialStartDate;
    _selectedEndDate = widget.initialEndDate;
    _selectedCategory = widget.initialCategory; // Initialize with String
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _selectedStartDate : _selectedEndDate) ??
          DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          // Ensure end date is not before start date
          if (_selectedEndDate != null &&
              _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = picked;
          // Ensure start date is not after end date
          if (_selectedStartDate != null &&
              _selectedStartDate!.isAfter(_selectedEndDate!)) {
            _selectedStartDate = _selectedEndDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Expenses'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Start Date Picker Tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedStartDate == null
                  ? 'Start Date (Optional)'
                  : 'Start: ${DateFormatter.formatDate(_selectedStartDate!)}'), // Use your formatter
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, true),
            ),
            // End Date Picker Tile
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedEndDate == null
                  ? 'End Date (Optional)'
                  : 'End: ${DateFormatter.formatDate(_selectedEndDate!)}'), // Use your formatter
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 15),
            // Category Dropdown using String
            DropdownButtonFormField<String>(
              value: _selectedCategory, // Uses String
              hint: const Text('Category (Optional)'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null, // Represents 'All Categories'
                  child: Text('All Categories'),
                ),
                ..._categoryNames.map((String categoryName) {
                  return DropdownMenuItem<String>(
                    value: categoryName, // Value is String
                    child: Text(categoryName),
                  );
                }).toList(),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue; // Updates String state
                });
              },
              decoration: const InputDecoration(
                labelText: 'Category', // Added label for clarity
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 8.0), // Adjust padding
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        // Clear Filters Button
        TextButton(
          child: const Text('Clear Filters'),
          onPressed: widget.onClearFilter,
        ),
        // Cancel Button
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Apply Filters Button
        ElevatedButton(
          child: const Text('Apply'),
          // Passes the String category back
          onPressed: () => widget.onApplyFilter(
              _selectedStartDate, _selectedEndDate, _selectedCategory),
        ),
      ],
    );
  }
}
