// lib/core/common/generic_list_page.dart
// MODIFIED FILE (Simplified - Removed interaction logic from ListView.builder)
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
// Only Category entity needed here for types
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
// Removed specific use case imports like save_user_categorization_history
// Removed category picker import - handled by concrete pages
// Removed specific list bloc imports
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- SIMPLIFIED ItemWidgetBuilder ---
// Receives item data and selection state. Returns the widget to display.
// Interaction logic (taps, etc.) is handled by the concrete page's implementation of this builder.
typedef ItemWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  bool isSelected,
);
// --- END SIMPLIFIED ---

typedef TableWidgetBuilder<T> = Widget Function(
    BuildContext context, List<T> items);
typedef EmptyStateWidgetBuilder = Widget Function(
    BuildContext context, bool filtersApplied);
typedef FilterDialogBuilder = void Function(
    BuildContext context, BaseListState currentState)?;
typedef DeleteConfirmationBuilder<T> = Future<bool> Function(
    BuildContext context, T item);
typedef DeleteEventBuilder<E> = E Function(String id);
typedef LoadEventBuilder<E> = E Function({bool forceReload});
// UserCategorizedEventBuilder is no longer needed here

class GenericListPage<T, B extends Bloc<E, S>, E, S> extends StatefulWidget {
  final String pageTitle;
  final String addRouteName;
  final String editRouteName; // Used for edit navigation from concrete page
  final String itemHeroTagPrefix;
  final String fabHeroTag;
  final bool showSummaryCard;
  final ItemWidgetBuilder<T> itemBuilder; // Corrected Type
  final TableWidgetBuilder<T>? tableBuilder;
  final EmptyStateWidgetBuilder emptyStateBuilder;
  final FilterDialogBuilder filterDialogBuilder;
  final DeleteConfirmationBuilder<T> deleteConfirmationBuilder;
  final DeleteEventBuilder<E> deleteEventBuilder;
  final LoadEventBuilder<E> loadEventBuilder;
  // final UserCategorizedEventBuilder<E, T>? userCategorizedEventBuilder; // REMOVED
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;

  const GenericListPage({
    super.key,
    required this.pageTitle,
    required this.addRouteName,
    required this.editRouteName, // Keep for reference
    required this.itemBuilder, // Corrected Type
    this.tableBuilder,
    required this.emptyStateBuilder,
    this.filterDialogBuilder,
    required this.deleteConfirmationBuilder,
    required this.deleteEventBuilder,
    required this.loadEventBuilder,
    required this.itemHeroTagPrefix,
    required this.fabHeroTag,
    this.showSummaryCard = false,
    // this.userCategorizedEventBuilder, // REMOVED
    this.appBarActions,
    this.floatingActionButton,
  });

  @override
  _GenericListPageState<T, B, E, S> createState() =>
      _GenericListPageState<T, B, E, S>();
}

class _GenericListPageState<T, B extends Bloc<E, S>, E, S>
    extends State<GenericListPage<T, B, E, S>> {
  // Blocs are accessed via context where needed now

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure BlocProvider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final listBloc = BlocProvider.of<B>(context); // Access via context
      final S initialState = listBloc.state;
      if (initialState is BaseListInitialState) {
        log.info(
            "[GenericListPage-${widget.pageTitle}] Main Bloc initial, dispatching load event.");
        listBloc.add(widget.loadEventBuilder(forceReload: false));
      }
      // AccountListBloc loading (if needed) should be handled by the concrete page that provides it
    });
  }

  Future<void> _refreshList() async {
    log.info(
        "[GenericListPage-${widget.pageTitle}] Pull-to-refresh triggered.");
    try {
      final listBloc = BlocProvider.of<B>(context);
      listBloc.add(widget.loadEventBuilder(forceReload: true));
      // Optional: Trigger account refresh if needed (handled by concrete page's refresh logic perhaps)
      await listBloc.stream
          .firstWhere((state) =>
              state is BaseListState<T> || state is BaseListErrorState)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        log.warning(
            "[GenericListPage-${widget.pageTitle}] Refresh stream timed out.");
        return listBloc.state; // Return current state
      });
      log.info(
          "[GenericListPage-${widget.pageTitle}] Refresh stream finished or timed out.");
    } catch (e) {
      log.warning(
          "[GenericListPage-${widget.pageTitle}] Error during refresh: $e");
    }
  }

  void _navigateToAdd() {
    log.info("[GenericListPage-${widget.pageTitle}] Navigating to Add.");
    context.pushNamed(widget.addRouteName);
  }

  @override
  Widget build(BuildContext context) {
    log.info("[GenericListPage-${widget.pageTitle}] Build method called.");
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final modeTheme = context.modeTheme;
    final useTables = modeTheme?.preferDataTableForLists ?? false;
    final uiMode = settingsState.uiMode;

    // Access the specific list Bloc via context.watch or context.read inside BlocBuilder/Consumer
    // final listBloc = context.watch<B>(); // Example

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        actions: [
          // Filter Button still makes sense here
          if (widget.filterDialogBuilder != null)
            BlocBuilder<B, S>(
              // Watches the specific Bloc B
              builder: (context, state) {
                bool filtersApplied = false;
                if (state is BaseListState<T>) {
                  filtersApplied = state.filtersApplied;
                }
                return IconButton(
                    icon: Icon(filtersApplied
                        ? Icons.filter_list
                        : Icons.filter_list_off_outlined),
                    tooltip: 'Filter ${widget.pageTitle}',
                    onPressed: () {
                      if (state is BaseListState) {
                        widget.filterDialogBuilder!(context, state);
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              "Cannot filter while loading or in error state."),
                          duration: Duration(seconds: 2),
                        ));
                      }
                    });
              },
            ),
          ...?widget.appBarActions, // Display actions passed by concrete page
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: Column(
          children: [
            if (widget.showSummaryCard) const SummaryCard(),
            if (widget.showSummaryCard) const Divider(),
            Expanded(
              child: BlocConsumer<B, S>(
                // Consumes the specific Bloc B
                listener: (context, state) {
                  if (state is BaseListErrorState) {
                    log.warning(
                        "[GenericListPage-${widget.pageTitle}] Error state detected: ${state.message}");
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                          content: Text(state.message),
                          backgroundColor: theme.colorScheme.error));
                  }
                },
                builder: (context, state) {
                  log.info(
                      "[GenericListPage-${widget.pageTitle}] BlocBuilder building for state: ${state.runtimeType}");
                  Widget content;

                  if (state is BaseListLoadingState && !state.isReloading) {
                    content = const Center(child: CircularProgressIndicator());
                  } else if (state is BaseListState<T> ||
                      (state is BaseListLoadingState && state.isReloading)) {
                    final BaseListState<T>? loadedState =
                        state is BaseListState<T>
                            ? state
                            : (context.read<B>().state is BaseListState<T>
                                ? context.read<B>().state as BaseListState<T>
                                : null);
                    if (loadedState == null) {
                      content =
                          const Center(child: CircularProgressIndicator());
                    } else {
                      final items = loadedState.items;
                      final filtersApplied =
                          widget.filterDialogBuilder != null &&
                              loadedState.filtersApplied;

                      // --- Get Batch Edit State from the SPECIFIC state type ---
                      bool isInBatchEditMode = false;
                      Set<String> selectedIds = {};
                      if (state is ExpenseListLoaded) {
                        // Check specific state type
                        isInBatchEditMode = state.isInBatchEditMode;
                        selectedIds = state.selectedTransactionIds;
                      } else if (state is IncomeListLoaded) {
                        // Check specific state type
                        isInBatchEditMode = state.isInBatchEditMode;
                        selectedIds = state.selectedTransactionIds;
                      }
                      // --- END GET ---

                      if (items.isEmpty) {
                        content =
                            widget.emptyStateBuilder(context, filtersApplied);
                      } else {
                        bool showTable = uiMode == UIMode.quantum &&
                            useTables &&
                            widget.tableBuilder != null;
                        if (showTable) {
                          content = widget.tableBuilder!(context, items);
                        } else {
                          content = ListView.separated(
                            key: ValueKey(
                                '${widget.itemHeroTagPrefix}_list_${items.length}_batch:$isInBatchEditMode'), // Include batch mode in key
                            padding: modeTheme?.pagePadding
                                    .copyWith(top: 8, bottom: 80) ??
                                const EdgeInsets.only(top: 8, bottom: 80),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final String itemId = (item as dynamic).id;
                              final bool isSelected = selectedIds
                                  .contains(itemId); // Get selection status

                              // --- Call the itemBuilder provided by the CONCRETE PAGE ---
                              // It receives the selection state and renders the item with necessary wrappers/interactions.
                              Widget listItem =
                                  widget.itemBuilder(context, item, isSelected);
                              // --- END Call ---

                              return Dismissible(
                                key: Key('${widget.itemHeroTagPrefix}_$itemId'),
                                direction: isInBatchEditMode
                                    ? DismissDirection.none
                                    : DismissDirection
                                        .endToStart, // Use correct state check
                                background: Container(
                                  /* ... delete background ... */ color:
                                      Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text("Delete",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onErrorContainer,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Icon(Icons.delete_sweep_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) => widget
                                    .deleteConfirmationBuilder(context, item),
                                onDismissed: (direction) {
                                  log.info(
                                      "[GenericListPage-${widget.pageTitle}] Dismissed item ID: $itemId. Dispatching delete.");
                                  context
                                      .read<B>()
                                      .add(widget.deleteEventBuilder(itemId));
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(SnackBar(
                                      content: Text(
                                          '${widget.pageTitle.substring(0, widget.pageTitle.length - 1)} deleted.'),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 2),
                                    ));
                                },
                                child: listItem,
                              )
                                  .animate(
                                      delay: (modeTheme?.listAnimationDelay ??
                                              const Duration(
                                                  milliseconds: 50)) *
                                          index)
                                  .fadeIn(
                                      duration:
                                          modeTheme?.listAnimationDuration ??
                                              const Duration(milliseconds: 400))
                                  .slideY(
                                      begin: 0.2,
                                      curve: modeTheme?.primaryCurve ??
                                          Curves.easeOut);
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 0),
                          );
                        }
                      }
                    }
                  } else if (state is BaseListErrorState) {
                    content = Center(
                      /* ... error UI ... */ child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: theme.colorScheme.error, size: 50),
                            const SizedBox(height: 16),
                            Text('Error Loading ${widget.pageTitle}',
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(state.message,
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: theme.colorScheme.error)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              onPressed: () => context.read<B>().add(
                                  widget.loadEventBuilder(forceReload: true)),
                            )
                          ],
                        ),
                      ),
                    );
                  } else {
                    content = const Center(child: CircularProgressIndicator());
                  }

                  return AnimatedSwitcher(
                    duration: modeTheme?.mediumDuration ??
                        const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                        key: ValueKey(state.runtimeType.toString() +
                            (state is BaseListState
                                ? state.items.length.toString()
                                : '') +
                            (state is ExpenseListLoaded
                                ? state.isInBatchEditMode.toString()
                                : '') +
                            (state is IncomeListLoaded
                                ? state.isInBatchEditMode.toString()
                                : '')),
                        child: content), // Add batch mode to key
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Use the FAB provided by the concrete page, or default Add FAB
      floatingActionButton: widget.floatingActionButton ??
          FloatingActionButton(
            heroTag: widget.fabHeroTag,
            onPressed: _navigateToAdd,
            tooltip:
                'Add ${widget.pageTitle.substring(0, widget.pageTitle.length - 1)}',
            child: modeTheme != null &&
                    modeTheme.assets
                        .getCommonIcon(AssetKeys.iconAdd, defaultPath: '')
                        .isNotEmpty
                ? SvgPicture.asset(
                    modeTheme.assets.getCommonIcon(AssetKeys.iconAdd,
                        defaultPath: AppAssets.elComIconAdd),
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                        theme.floatingActionButtonTheme.foregroundColor ??
                            Colors.white,
                        BlendMode.srcIn))
                : const Icon(Icons.add),
          ),
    );
  }
}
