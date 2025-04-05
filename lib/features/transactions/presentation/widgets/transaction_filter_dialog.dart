import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart'; // Re-use account selector
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Callback type for applying filters
typedef ApplyFiltersCallback = void Function(
  DateTime? startDate,
  DateTime? endDate,
  TransactionType? transactionType,
  String? accountId,
  String? categoryId,
);

class TransactionFilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final TransactionType? initialTransactionType;
  final String? initialAccountId;
  final String? initialCategoryId;
  final ApplyFiltersCallback onApplyFilter;
  final VoidCallback onClearFilter;
  final List<Category> availableCategories; // Pass categories from BLoC/UseCase

  const TransactionFilterDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialTransactionType,
    this.initialAccountId,
    this.initialCategoryId,
    required this.onApplyFilter,
    required this.onClearFilter,
    required this.availableCategories,
  });

  @override
  State<TransactionFilterDialog> createState() =>
      _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
  late DateTime? _selectedStartDate;
  late DateTime? _selectedEndDate;
  late TransactionType? _selectedTransactionType;
  late String? _selectedAccountId;
  late String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.initialStartDate;
    _selectedEndDate = widget.initialEndDate;
    _selectedTransactionType = widget.initialTransactionType;
    _selectedAccountId = widget.initialAccountId;
    _selectedCategoryId = widget.initialCategoryId;
    // Ensure AccountListBloc is loaded if AccountSelectorDropdown needs it
    // This assumes AccountListBloc is provided higher up via MultiBlocProvider
    context.read<AccountListBloc>().add(const LoadAccounts());
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial =
        (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101), // Adjust range as needed
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = DateTime(
              picked.year, picked.month, picked.day); // Store date only
          // Adjust end date if necessary
          if (_selectedEndDate != null &&
              _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = DateTime(
              picked.year, picked.month, picked.day, 23, 59, 59); // End of day
          // Adjust start date if necessary
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
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    // Prepare category dropdown items
    final categoryDropdownItems = [
      const DropdownMenuItem<String>(
          value: null, // Represents "All Categories"
          child: Text('All Categories')),
      ...widget.availableCategories
          .where((cat) =>
              cat.id != Category.uncategorized.id) // Exclude uncategorized
          .map((Category category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Row(
            children: [
              // TODO: Add category icon rendering here later
              Icon(Icons.circle, color: category.displayColor, size: 12),
              const SizedBox(width: 8),
              Text(category.name, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }).toList(),
    ];

    return AlertDialog(
      title: const Text('Filter Transactions'),
      contentPadding:
          const EdgeInsets.fromLTRB(16, 20, 16, 0), // Adjusted padding
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- Date Range ---
            Text('Date Range', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.date_range_outlined,
                        color: theme.iconTheme.color),
                    title: Text(
                        _selectedStartDate == null
                            ? 'Start Date'
                            : DateFormatter.formatDate(_selectedStartDate!),
                        style: theme.textTheme.bodyMedium),
                    trailing: _selectedStartDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _selectedStartDate = null),
                            tooltip: "Clear Start Date",
                            visualDensity: VisualDensity.compact)
                        : null,
                    onTap: () => _selectDate(context, true),
                    dense: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('-', style: theme.textTheme.titleMedium),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.date_range, color: theme.iconTheme.color),
                    title: Text(
                        _selectedEndDate == null
                            ? 'End Date'
                            : DateFormatter.formatDate(_selectedEndDate!),
                        style: theme.textTheme.bodyMedium),
                    trailing: _selectedEndDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _selectedEndDate = null),
                            tooltip: "Clear End Date",
                            visualDensity: VisualDensity.compact)
                        : null,
                    onTap: () => _selectDate(context, false),
                    dense: true,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // --- Transaction Type ---
            DropdownButtonFormField<TransactionType?>(
              value: _selectedTransactionType,
              decoration: InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(
                    _selectedTransactionType == TransactionType.expense
                        ? Icons.arrow_downward
                        : _selectedTransactionType == TransactionType.income
                            ? Icons.arrow_upward
                            : Icons.swap_vert,
                    size: 20),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              hint: const Text('All Types'),
              isExpanded: true,
              items: const [
                DropdownMenuItem<TransactionType?>(
                    value: null, child: Text('All Types')),
                DropdownMenuItem<TransactionType?>(
                    value: TransactionType.expense,
                    child: Text('Expenses Only')),
                DropdownMenuItem<TransactionType?>(
                    value: TransactionType.income, child: Text('Income Only')),
              ],
              onChanged: (TransactionType? newValue) {
                setState(() => _selectedTransactionType = newValue);
              },
            ),
            const SizedBox(height: 16),

            // --- Account Selector ---
            AccountSelectorDropdown(
                // Reuse existing widget
                selectedAccountId: _selectedAccountId,
                labelText: 'Account',
                hintText: 'All Accounts',
                validator: null, // No validation needed for filter
                onChanged: (String? newAccountId) {
                  setState(() => _selectedAccountId = newAccountId);
                }),
            const SizedBox(height: 16),

            // --- Category Selector ---
            DropdownButtonFormField<String?>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              hint: const Text('All Categories'),
              isExpanded: true,
              items: categoryDropdownItems,
              onChanged: (String? newValue) {
                setState(() => _selectedCategoryId = newValue);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: <Widget>[
        TextButton(
            child: const Text('Clear All'),
            onPressed: () {
              widget.onClearFilter();
              Navigator.of(context).pop();
            }),
        const Spacer(), // Push buttons to the right
        TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
            child: const Text('Apply Filters'),
            onPressed: () {
              widget.onApplyFilter(
                  _selectedStartDate,
                  _selectedEndDate,
                  _selectedTransactionType,
                  _selectedAccountId,
                  _selectedCategoryId);
              Navigator.of(context).pop();
            }),
      ],
    );
  }
}
