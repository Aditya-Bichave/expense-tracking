// lib/features/income/presentation/widgets/income_list_page.dart
// MODIFIED FILE

import 'package:expense_tracker/core/common/generic_list_page.dart';
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
// Assuming FilterDialogContent is in ExpenseListPage for now
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:go_router/go_router.dart';

class IncomeListPage extends StatelessWidget {
  const IncomeListPage({super.key});

  // --- Navigation ---
  void _navigateToEdit(BuildContext context, Income item) {
    log.info("[IncomeListPage] Navigating to Edit item ID: ${item.id}");
    context.pushNamed(RouteNames.editIncome,
        pathParameters: {RouteNames.paramId: item.id}, extra: item);
  }

  // --- Category Interaction Handlers ---
  void _handleChangeCategoryRequest(BuildContext context, Income item) async {
    log.info(
        "[IncomeListPage] Change category requested for item ID: ${item.id}");
    // FIX: Pass the required CategoryTypeFilter
    final Category? selectedCategory =
        await showCategoryPicker(context, CategoryTypeFilter.income);
    if (selectedCategory != null && context.mounted) {
      log.info(
          "[IncomeListPage] Category '${selectedCategory.name}' selected from picker.");
      final matchData =
          TransactionMatchData(description: item.title, merchantId: null);
      context.read<IncomeListBloc>().add(UserCategorizedIncome(
          incomeId: item.id,
          selectedCategory: selectedCategory,
          matchData: matchData));
    } else {
      log.info("[IncomeListPage] Category picker dismissed without selection.");
    }
  }

  void _handleUserCategorized(
      BuildContext context, Income item, Category selectedCategory) {
    log.info(
        "[IncomeListPage] User categorized item ID: ${item.id} as ${selectedCategory.name}");
    final matchData =
        TransactionMatchData(description: item.title, merchantId: null);
    context.read<IncomeListBloc>().add(UserCategorizedIncome(
        incomeId: item.id,
        selectedCategory: selectedCategory,
        matchData: matchData));
  }

  // --- Build Methods ---

  Widget _buildIncomeItem(
    BuildContext context,
    Income item,
    bool isSelected,
    // Callbacks provided by GenericListPage
    VoidCallback onEditTap,
    VoidCallback onSelectTap,
    Function(Category selectedCategory) onCategoryConfirmed,
    VoidCallback onChangeCategoryRequest,
  ) {
    final theme = Theme.of(context);
    Widget card = IncomeCard(
      income: item,
      // --- CORRECTED Callback Wiring ---
      onCardTap: (_) => onEditTap(),
      onUserCategorized: (_, cat) => onCategoryConfirmed(cat),
      onChangeCategoryRequest: (_) => onChangeCategoryRequest(),
      // --- END CORRECTION ---
    );

    final bloc = context.read<IncomeListBloc>();
    if (bloc.state is IncomeListLoaded &&
        (bloc.state as IncomeListLoaded).isInBatchEditMode) {
      card = Stack(
        children: [
          card,
          Positioned.fill(
            child: Material(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
              child: InkWell(
                onTap: onSelectTap,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IgnorePointer(
                        child: Checkbox(
                      value: isSelected,
                      onChanged: null,
                      visualDensity: VisualDensity.compact,
                    )),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return card;
  }

  Widget _buildIncomeTable(BuildContext context, List<Income> items) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final accountState = context.watch<AccountListBloc>().state;
    final rows = items.map((inc) {
      String accountName = '...';
      if (accountState is AccountListLoaded) {
        try {
          accountName = accountState.items
              .firstWhere((acc) => acc.id == inc.accountId)
              .name;
        } catch (_) {
          accountName = 'N/A';
        }
      } else if (accountState is AccountListError) {
        accountName = 'Error';
      }
      final categoryName = inc.category?.name ?? Category.uncategorized.name;
      return DataRow(cells: [
        DataCell(Text(DateFormatter.formatDate(inc.date),
            style: theme.textTheme.bodySmall)),
        DataCell(Text(inc.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(categoryName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(accountName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(
          CurrencyFormatter.format(inc.amount, currencySymbol),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.tertiary, fontWeight: FontWeight.w500),
          textAlign: TextAlign.end,
        )),
      ]);
    }).toList();
    return Card(
      margin: EdgeInsets.zero,
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      clipBehavior: theme.cardTheme.clipBehavior ?? Clip.none,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
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
      BuildContext context, BaseListState currentState) async {
    log.info("[IncomeListPage] Showing filter dialog.");
    final getCategoriesUseCase = sl<GetCategoriesUseCase>();
    final categoriesResult = await getCategoriesUseCase(const NoParams());
    List<String> categoryNames = [];
    if (categoriesResult.isRight()) {
      categoryNames =
          categoriesResult.getOrElse(() => []).map((cat) => cat.name).toList();
      categoryNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } else {
      log.warning(
          "[IncomeListPage] Failed to load categories for filter dialog.");
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
          value: sl<AccountListBloc>(),
          child: FilterDialogContent(
            // Reuse the same dialog widget
            categoryNames: categoryNames,
            initialStartDate: currentState.filterStartDate,
            initialEndDate: currentState.filterEndDate,
            initialCategoryName: currentState.filterCategory,
            initialAccountId: currentState.filterAccountId,
            onApplyFilter: (startDate, endDate, categoryName, accountId) {
              log.info(
                  "[IncomeListPage] Filter dialog applied. Start=$startDate, End=$endDate, Cat=$categoryName, AccID=$accountId");
              context.read<IncomeListBloc>().add(FilterIncomes(
                  startDate: startDate,
                  endDate: endDate,
                  category: categoryName,
                  accountId: accountId));
              Navigator.of(dialogContext).pop();
            },
            onClearFilter: () {
              log.info("[IncomeListPage] Filter dialog cleared.");
              context.read<IncomeListBloc>().add(const FilterIncomes());
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmIncomeDeletion(BuildContext context, Income item) async {
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<IncomeListBloc>(
            create: (_) => sl<IncomeListBloc>()..add(const LoadIncomes())),
        BlocProvider<AccountListBloc>.value(value: sl<AccountListBloc>()),
      ],
      child: BlocBuilder<IncomeListBloc, IncomeListState>(
          builder: (context, state) {
        final bool isInBatchEditMode =
            state is IncomeListLoaded && state.isInBatchEditMode;
        final int selectionCount =
            state is IncomeListLoaded ? state.selectedTransactionIds.length : 0;
        final theme = Theme.of(context);

        return GenericListPage<Income, IncomeListBloc, IncomeListEvent,
            IncomeListState>(
          pageTitle: 'Income',
          addRouteName: RouteNames.addIncome,
          editRouteName: RouteNames.editIncome,
          itemHeroTagPrefix: 'income',
          fabHeroTag: 'fab_income',
          showSummaryCard: false,
          // Provide OUR item builder implementation
          itemBuilder: (itemBuilderContext, item, isSelected) =>
              _buildIncomeItem(
                  itemBuilderContext,
                  item,
                  isSelected,
                  // Implement the callbacks required by ItemWidgetBuilder
                  () => _navigateToEdit(context, item), // Use page's context
                  () => context
                      .read<IncomeListBloc>()
                      .add(SelectIncome(item.id)), // Handle select tap
                  (selectedCategory) => _handleUserCategorized(
                      context, item, selectedCategory), // Use page's context
                  () => _handleChangeCategoryRequest(
                      context, item) // Use page's context
                  ),
          tableBuilder: _buildIncomeTable,
          emptyStateBuilder: _buildEmptyState,
          filterDialogBuilder: (dialogContext, currentState) =>
              _showIncomeFilterDialog(dialogContext, currentState),
          deleteConfirmationBuilder: (dialogContext, item) =>
              _confirmIncomeDeletion(dialogContext, item),
          deleteEventBuilder: (id) => DeleteIncomeRequested(id),
          loadEventBuilder: ({bool forceReload = false}) =>
              LoadIncomes(forceReload: forceReload),
          // --- Provide specific AppBar Actions and FAB ---
          appBarActions: [
            IconButton(
              icon: Icon(isInBatchEditMode
                  ? Icons.cancel_outlined
                  : Icons.edit_note_outlined),
              tooltip:
                  isInBatchEditMode ? "Cancel Selection" : "Select Multiple",
              onPressed: () => context
                  .read<IncomeListBloc>()
                  .add(const ToggleBatchEditMode()),
            )
          ],
          floatingActionButton: isInBatchEditMode
              ? FloatingActionButton.extended(
                  heroTag: "fab_income_batch",
                  onPressed: selectionCount > 0
                      ? () async {
                          // FIX: Pass the required CategoryTypeFilter
                          final Category? selectedCategory =
                              await showCategoryPicker(
                                  context, CategoryTypeFilter.income);
                          if (selectedCategory != null &&
                              selectedCategory.id !=
                                  Category.uncategorized.id &&
                              context.mounted) {
                            context
                                .read<IncomeListBloc>()
                                .add(ApplyBatchCategory(selectedCategory.id));
                          } else if (selectedCategory?.id ==
                                  Category.uncategorized.id &&
                              context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please select a specific category for batch editing.")));
                          }
                        }
                      : null,
                  label: Text(selectionCount > 0
                      ? 'Categorize ($selectionCount)'
                      : 'Categorize'),
                  icon: const Icon(Icons.category),
                  backgroundColor: selectionCount > 0
                      ? theme.colorScheme.primaryContainer
                      : theme.disabledColor.withOpacity(0.1),
                  foregroundColor: selectionCount > 0
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.disabledColor,
                )
              : null, // No FAB if not in batch mode
        );
      }),
    );
  }
}
