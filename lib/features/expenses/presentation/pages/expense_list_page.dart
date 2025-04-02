// ... other imports ...
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  // Method to handle refresh
  Future<void> _refreshExpenses(BuildContext context) async {
    context.read<ExpenseListBloc>().add(LoadExpenses());
    context.read<SummaryBloc>().add(const LoadSummary()); // Refresh summary too
    // Wait for states to settle if needed, similar to account list
    await Future.wait([
      context.read<ExpenseListBloc>().stream.firstWhere(
          (state) => state is ExpenseListLoaded || state is ExpenseListError),
      context.read<SummaryBloc>().stream.firstWhere(
          (state) => state is SummaryLoaded || state is SummaryError),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
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
        onRefresh: () => _refreshExpenses(context), // Use the refresh method
        child: Column(
          children: [
            const SummaryCard(), // Assumes SummaryBloc is provided globally
            const Divider(height: 1),
            Expanded(
              child: BlocConsumer<ExpenseListBloc, ExpenseListState>(
                listener: (context, state) {
                  if (state is ExpenseListError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Error: ${state.message}"),
                          backgroundColor: Theme.of(context).colorScheme.error),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ExpenseListLoading &&
                      state is! ExpenseListLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ExpenseListLoaded) {
                    if (state.expenses.isEmpty) {
                      return Center(
                        // Display when list is empty
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
                                  context
                                      .read<ExpenseListBloc>()
                                      .add(const FilterExpenses());
                                  context
                                      .read<SummaryBloc>()
                                      .add(const LoadSummary());
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
                    return ListView.builder(
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
                            context
                                .read<ExpenseListBloc>()
                                .add(DeleteExpenseRequested(expense.id));
                            context.read<SummaryBloc>().add(
                                const LoadSummary()); // Refresh summary after delete
                          },
                          child: ExpenseCard(
                            // Assuming ExpenseCard takes the expense
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
                    return Center(
                      // Error UI
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
                              onPressed: () => context
                                  .read<ExpenseListBloc>()
                                  .add(LoadExpenses()),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  return const Center(
                      child: CircularProgressIndicator()); // Initial state
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // --- FIX: Added unique heroTag ---
        heroTag: 'fab_expenses',
        // ---------------------------------
        onPressed: () {
          context.pushNamed('add_expense');
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Filter Dialog Logic (Keep unchanged) ---
  void _showFilterDialog(BuildContext context, DateTime? currentStart,
      DateTime? currentEnd, String? currentCategoryName) {
    // ... (FilterDialogContent widget and showDialog call remains the same) ...
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
              // Receive category NAME string
              // Dispatch FilterExpenses with the STRING category name
              context.read<ExpenseListBloc>().add(FilterExpenses(
                    startDate: startDate,
                    endDate: endDate,
                    category: categoryName, // Pass the String name
                  ));
              // Refresh summary based on date filters
              context.read<SummaryBloc>().add(LoadSummary(
                    startDate: startDate,
                    endDate: endDate,
                  ));
              Navigator.of(dialogContext).pop(); // Close dialog
            },
            onClearFilter: () {
              // Dispatch FilterExpenses with null values to clear filters
              context.read<ExpenseListBloc>().add(const FilterExpenses(
                    startDate: null,
                    endDate: null,
                    category: null,
                  ));
              // Refresh summary with no date filters
              context.read<SummaryBloc>().add(const LoadSummary(
                    startDate: null,
                    endDate: null,
                  ));
              Navigator.of(dialogContext).pop(); // Close dialog
            });
      },
    );
  }
} // END of ExpenseListPage class

// --- FilterDialogContent Widget (Assume this is defined correctly below or imported) ---
class FilterDialogContent extends StatefulWidget {
  // ... same as before ...
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
  // ... same implementation as before ...
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategory; // Stores String
  final List<String> _categoryNames = PredefinedCategory.values
      .map((e) =>
          Category.fromPredefined(e).name) // Creates list of String names
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
                  // Uses String
                  value: null, // Represents 'All Categories'
                  child: Text('All Categories'),
                ),
                ..._categoryNames.map((String categoryName) {
                  // Iterates over String names
                  return DropdownMenuItem<String>(
                    // Uses String
                    value: categoryName, // Value is String
                    child: Text(categoryName),
                  );
                }).toList(),
              ],
              onChanged: (String? newValue) {
                // Receives String?
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
