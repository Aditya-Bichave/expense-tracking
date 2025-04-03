// lib/features/income/presentation/widgets/income_list_page.dart
import 'package:expense_tracker/core/common/generic_list_page.dart'; // Import Generic List Page
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart'; // Import AssetKeys
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'
    as entityCategory; // Expense categories for filter dialog
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart'; // Import shared FilterDialogContent
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart'; // Default assets

import 'package:expense_tracker/core/utils/app_dialogs.dart';

class IncomeListPage extends StatelessWidget {
  const IncomeListPage({super.key});

  // --- Specific Builders for Income ---

  Widget _buildIncomeItem(
      BuildContext context, Income item, VoidCallback onTapEdit) {
    // IncomeCard needs AccountListBloc provided higher up (GenericListPage does this)
    return IncomeCard(income: item, onTap: onTapEdit);
  }

  Widget _buildIncomeTable(BuildContext context, List<Income> items) {
    // This is the logic from the old _buildQuantumIncomeTable
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    // AccountListBloc is provided by GenericListPage
    final accountState = context.watch<AccountListBloc>().state;

    final rows = items.map((inc) {
      String accountName = '...';
      if (accountState is AccountListLoaded) {
        try {
          accountName = accountState.items // Use items from base state
              .firstWhere((acc) => acc.id == inc.accountId)
              .name;
        } catch (_) {
          accountName = 'N/A';
        }
      } else if (accountState is AccountListError) {
        accountName = 'Error';
      }

      return DataRow(cells: [
        DataCell(Text(DateFormatter.formatDate(inc.date),
            style: theme.textTheme.bodySmall)), // Date
        DataCell(Text(inc.title, overflow: TextOverflow.ellipsis)), // Title
        DataCell(Text(inc.category.name,
            overflow: TextOverflow.ellipsis)), // Category
        DataCell(Text(accountName, overflow: TextOverflow.ellipsis)), // Account
        DataCell(Text(
          CurrencyFormatter.format(inc.amount, currencySymbol),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.tertiary, // Use Tertiary for income
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.end,
        )), // Amount
      ]);
    }).toList();

    // Consistent Card wrapping for the table
    return Card(
      margin: EdgeInsets.zero,
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      clipBehavior: theme.cardTheme.clipBehavior ?? Clip.none,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          /* ... DataTable properties ... */
          columnSpacing: theme.dataTableTheme.columnSpacing ?? 12,
          headingRowHeight: theme.dataTableTheme.headingRowHeight ?? 36,
          dataRowMinHeight: theme.dataTableTheme.dataRowMinHeight ?? 36,
          dataRowMaxHeight: theme.dataTableTheme.dataRowMaxHeight ?? 40,
          headingTextStyle: theme.dataTableTheme.headingTextStyle ??
              theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          dataTextStyle:
              theme.dataTableTheme.dataTextStyle ?? theme.textTheme.bodySmall,
          dividerThickness: theme.dataTableTheme.dividerThickness,
          dataRowColor: theme.dataTableTheme.dataRowColor,
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Account')),
            DataColumn(label: Text('Amount'), numeric: true),
          ],
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool filtersApplied) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    String emptyText = filtersApplied
        ? 'No income matches filters.'
        : 'No income recorded yet.';
    // Use appropriate illustrations
    String illustrationKey = filtersApplied
        ? AssetKeys.illuEmptyFilter
        : AssetKeys.illuEmptyTransactions;
    String defaultIllustration = filtersApplied
        ? AppAssets.elIlluEmptyCalendar
        : AppAssets.elIlluEmptyAddTransaction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
                modeTheme?.assets.getIllustration(illustrationKey,
                        defaultPath: defaultIllustration) ??
                    defaultIllustration,
                height: 100,
                colorFilter: ColorFilter.mode(
                    theme.colorScheme.secondary, BlendMode.srcIn)),
            const SizedBox(height: 16),
            Text(emptyText,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.secondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (filtersApplied)
              ElevatedButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  onPressed: () {
                    log.info(
                        "[IncomeListPage] Clearing filters via empty state.");
                    // Dispatch specific FilterIncomes event
                    context.read<IncomeListBloc>().add(const FilterIncomes());
                  })
            else
              Text('Tap "+" to add your first income!',
                  style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showIncomeFilterDialog(
      BuildContext context, BaseListState currentState) {
    log.info("[IncomeListPage] Showing filter dialog.");
    // Get category names
    final List<String> incomeCategoryNames = PredefinedIncomeCategory.values
        .map<String>((e) => IncomeCategory.fromPredefined(e).name)
        .toList();
    // Get expense categories just to pass them (FilterDialog needs both lists)
    final List<String> expenseCategoryNames = entityCategory
        .PredefinedCategory.values
        .map<String>((e) => entityCategory.Category.fromPredefined(e).name)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Provide AccountListBloc for the dialog's dropdown
        return BlocProvider.value(
          value: sl<AccountListBloc>(),
          child: FilterDialogContent(
            isIncomeFilter: true, // Specify this is for income
            incomeCategoryNames: incomeCategoryNames,
            expenseCategoryNames:
                expenseCategoryNames, // Pass expense names too
            initialStartDate: currentState.filterStartDate,
            initialEndDate: currentState.filterEndDate,
            initialCategoryName: currentState.filterCategory,
            initialAccountId: currentState.filterAccountId,
            onApplyFilter: (startDate, endDate, categoryName, accountId) {
              log.info(
                  "[IncomeListPage] Filter dialog applied. Start=$startDate, End=$endDate, Cat=$categoryName, AccID=$accountId");
              // Dispatch specific FilterIncomes event
              context.read<IncomeListBloc>().add(FilterIncomes(
                  startDate: startDate,
                  endDate: endDate,
                  category: categoryName,
                  accountId: accountId));
              Navigator.of(dialogContext).pop(); // Close dialog
            },
            onClearFilter: () {
              log.info("[IncomeListPage] Filter dialog cleared.");
              // Dispatch specific FilterIncomes event with no args
              context.read<IncomeListBloc>().add(const FilterIncomes());
              Navigator.of(dialogContext).pop(); // Close dialog
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmIncomeDeletion(BuildContext context, Income item) async {
    // Reusing the generic confirmation dialog logic
    return await AppDialogs.showConfirmation(
          context,
          title: "Confirm Deletion",
          content:
              'Are you sure you want to delete the income "${item.title}"?',
          confirmText: "Delete",
          confirmColor: Theme.of(context).colorScheme.error,
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // Instantiate GenericListPage with Income-specific types and builders
    return GenericListPage<Income, IncomeListBloc, IncomeListEvent,
        IncomeListState>(
      pageTitle: 'Income',
      addRouteName: RouteNames.addIncome,
      editRouteName: RouteNames.editIncome,
      itemHeroTagPrefix: 'income', // Prefix for keys
      fabHeroTag: 'fab_income', // Unique FAB tag
      // Provide the specific builders and event creators
      itemBuilder: _buildIncomeItem,
      tableBuilder: _buildIncomeTable, // Pass the table builder for Quantum
      emptyStateBuilder: _buildEmptyState,
      filterDialogBuilder: _showIncomeFilterDialog,
      deleteConfirmationBuilder: _confirmIncomeDeletion,
      // Lambdas to create the correct event types
      deleteEventBuilder: (id) => DeleteIncomeRequested(id),
      loadEventBuilder: ({bool forceReload = false}) =>
          LoadIncomes(forceReload: forceReload),
    );
  }
}
