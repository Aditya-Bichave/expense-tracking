import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart'; // Needed for type check
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart'; // Import Summary Card
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart'; // Default assets
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate

// Type definitions for builder callbacks
typedef ItemWidgetBuilder<T> = Widget Function(
    BuildContext context, T item, VoidCallback onTapEdit);
typedef TableWidgetBuilder<T> = Widget Function(
    BuildContext context, List<T> items);
typedef EmptyStateWidgetBuilder = Widget Function(
    BuildContext context, bool filtersApplied);
// FilterDialogBuilder is nullable for pages without filtering
typedef FilterDialogBuilder = void Function(
    BuildContext context, BaseListState currentState)?;
typedef DeleteConfirmationBuilder<T> = Future<bool> Function(
    BuildContext context, T item);
typedef DeleteEventBuilder<E> = E Function(String id); // E is the Event type
typedef LoadEventBuilder<E> = E Function(
    {bool forceReload}); // E is the Event type

class GenericListPage<
    T, // Data type (Expense, Income, AssetAccount)
    B extends Bloc<E, S>, // Bloc type
    E, // Event type for the Bloc
    S> extends StatefulWidget {
  // S needs to be the specific Bloc State
  final String pageTitle;
  final String addRouteName;
  final String editRouteName;
  final String itemHeroTagPrefix; // e.g., 'expense', 'income', 'account'
  final String fabHeroTag;
  final bool showSummaryCard; // Flag to control summary card visibility

  // Callbacks for UI building
  final ItemWidgetBuilder<T> itemBuilder;
  final TableWidgetBuilder<T>? tableBuilder; // Optional table builder
  final EmptyStateWidgetBuilder emptyStateBuilder;
  final FilterDialogBuilder
      filterDialogBuilder; // Optional filter dialog builder
  final DeleteConfirmationBuilder<T> deleteConfirmationBuilder;

  // Callbacks for Bloc events
  final DeleteEventBuilder<E> deleteEventBuilder;
  final LoadEventBuilder<E> loadEventBuilder;

  const GenericListPage({
    super.key,
    required this.pageTitle,
    required this.addRouteName,
    required this.editRouteName,
    required this.itemBuilder,
    this.tableBuilder,
    required this.emptyStateBuilder,
    this.filterDialogBuilder, // Optional
    required this.deleteConfirmationBuilder,
    required this.deleteEventBuilder,
    required this.loadEventBuilder,
    required this.itemHeroTagPrefix,
    required this.fabHeroTag,
    this.showSummaryCard = false, // Default to false
  });

  @override
  // ignore: library_private_types_in_public_api
  _GenericListPageState<T, B, E, S> createState() =>
      _GenericListPageState<T, B, E, S>();
}

class _GenericListPageState<T, B extends Bloc<E, S>, E, S>
    extends State<GenericListPage<T, B, E, S>> {
  late B _listBloc;
  late AccountListBloc
      _accountListBloc; // Still needed for potential display in items

  @override
  void initState() {
    super.initState();
    _listBloc = sl<B>();
    _accountListBloc = sl<AccountListBloc>();

    // Ensure accounts are loaded if needed by item cards/tables, but not if this IS the accounts page
    if (_accountListBloc.state is AccountListInitial && T != AssetAccount) {
      log.info(
          "[GenericListPage-${widget.pageTitle}] AccountListBloc initial, loading accounts.");
      _accountListBloc.add(const LoadAccounts());
    }

    final S initialState = _listBloc.state;
    // Check the base initial state type
    if (initialState is BaseListInitialState) {
      log.info(
          "[GenericListPage-${widget.pageTitle}] Main Bloc initial, dispatching load event.");
      // Use the load event builder provided by the specific page implementation
      _listBloc.add(widget.loadEventBuilder(forceReload: false));
    }
  }

  Future<void> _refreshList() async {
    log.info(
        "[GenericListPage-${widget.pageTitle}] Pull-to-refresh triggered.");
    try {
      // Use the load event builder
      _listBloc.add(widget.loadEventBuilder(forceReload: true));
      // Only refresh accounts if the main type isn't Account
      if (T != AssetAccount) {
        _accountListBloc.add(const LoadAccounts(forceReload: true));
      }

      // Wait for the main list bloc to finish loading
      await _listBloc.stream
          .firstWhere((state) =>
              state is BaseListState<T> ||
              state is BaseListErrorState) // Check base states
          .timeout(const Duration(seconds: 5), onTimeout: () {
        log.warning(
            "[GenericListPage-${widget.pageTitle}] Refresh stream timed out.");
        return _listBloc.state; // Return current state on timeout
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

  void _navigateToEdit(T item) {
    // Assuming item has an 'id' property - requires T to have 'id' or casting
    final String itemId = (item as dynamic).id;
    log.info(
        "[GenericListPage-${widget.pageTitle}] Navigating to Edit item ID: $itemId");
    context.pushNamed(
      widget.editRouteName,
      pathParameters: {RouteNames.paramId: itemId}, // Use constant param name
      extra: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    log.info("[GenericListPage-${widget.pageTitle}] Build method called.");
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final modeTheme = context.modeTheme;
    final useTables = modeTheme?.preferDataTableForLists ?? false;
    final uiMode = settingsState.uiMode;

    // Provide the specific list Bloc and AccountListBloc down the tree
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _listBloc),
        BlocProvider.value(value: _accountListBloc), // Always provide for items
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pageTitle),
          actions: [
            // Conditionally show Filter Button only if a builder was provided
            if (widget.filterDialogBuilder != null)
              BlocBuilder<B, S>(
                builder: (context, state) {
                  bool filtersApplied = false;
                  // Check if the state implements the base and get filter status
                  if (state is BaseListState<T>) {
                    filtersApplied = state.filtersApplied;
                  }
                  return IconButton(
                      icon: Icon(filtersApplied
                          ? Icons.filter_list
                          : Icons.filter_list_off_outlined),
                      tooltip: 'Filter ${widget.pageTitle}',
                      onPressed: () {
                        // Ensure the state is loaded before showing filter dialog
                        if (state is BaseListState) {
                          // Call builder using ! because we checked for null above
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
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshList,
          child: Column(
            children: [
              // Conditionally show SummaryCard based on the flag
              if (widget.showSummaryCard) const SummaryCard(),
              // Add divider only if summary card is shown
              if (widget.showSummaryCard)
                Divider(
                    height: theme.dividerTheme.thickness ?? 1,
                    thickness: theme.dividerTheme.thickness ?? 1,
                    color: theme.dividerTheme.color),

              Expanded(
                // List/Table takes remaining space
                child: BlocConsumer<B, S>(
                  listener: (context, state) {
                    // Handle global errors shown in Snackbar using base state type
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

                    // --- Loading State ---
                    // Use base state type for check
                    if (state is BaseListLoadingState && !state.isReloading) {
                      content =
                          const Center(child: CircularProgressIndicator());
                    }
                    // --- Loaded or Reloading State ---
                    // Use base state type for check
                    else if (state is BaseListState<T> ||
                        (state is BaseListLoadingState && state.isReloading)) {
                      // Safely cast or access previous state if reloading
                      final BaseListState<T>? loadedState = state
                              is BaseListState<T>
                          ? state
                          // Access previous state IF it was loaded, otherwise null
                          : (_listBloc.state is BaseListState<T>
                              ? _listBloc.state as BaseListState<T>
                              : null);

                      if (loadedState == null) {
                        // This case might happen if forced reload occurs from Initial state
                        content = const Center(
                            child: CircularProgressIndicator()); // Show loading
                      } else {
                        final items = loadedState.items;
                        // Check if filter builder exists AND filters are applied in the state
                        final filtersApplied =
                            widget.filterDialogBuilder != null &&
                                loadedState.filtersApplied;

                        if (items.isEmpty) {
                          // --- Empty State ---
                          content =
                              widget.emptyStateBuilder(context, filtersApplied);
                        } else {
                          // --- List or Table View ---
                          // Determine if table view should be shown
                          bool showTable = uiMode == UIMode.quantum &&
                              useTables &&
                              widget.tableBuilder != null;
                          if (showTable) {
                            // Ensure tableBuilder is not null before calling
                            content = widget.tableBuilder!(context, items);
                          } else {
                            // Standard List View with Animations
                            content = ListView.separated(
                              // Add a key for AnimatedSwitcher identification
                              key: ValueKey(
                                  '${widget.itemHeroTagPrefix}_list_${items.length}'),
                              // Use themed padding or fallback, adjust for FAB
                              padding: modeTheme?.pagePadding
                                      .copyWith(top: 8, bottom: 80) ??
                                  const EdgeInsets.only(top: 8, bottom: 80),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                // Assuming item has an 'id' property - requires T to have 'id' or casting
                                final String itemId = (item as dynamic).id;
                                return Dismissible(
                                  key: Key(
                                      '${widget.itemHeroTagPrefix}_$itemId'), // Unique key for Dismissible
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Theme.of(context)
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
                                    // Use the delete event builder
                                    _listBloc
                                        .add(widget.deleteEventBuilder(itemId));
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(SnackBar(
                                        // Generate message like "Expense deleted." or "Income deleted."
                                        content: Text(
                                            '${widget.pageTitle.substring(0, widget.pageTitle.length - 1)} deleted.'),
                                        backgroundColor: Colors
                                            .orange, // Indicate deletion visually
                                        duration: const Duration(seconds: 2),
                                      ));
                                  },
                                  // Use the provided itemBuilder, passing the edit callback
                                  child: widget.itemBuilder(context, item,
                                      () => _navigateToEdit(item)),
                                )
                                    // Apply animation using flutter_animate
                                    .animate(
                                        // Use themed delay and duration, provide defaults
                                        delay: (modeTheme?.listAnimationDelay ??
                                                const Duration(
                                                    milliseconds: 50)) *
                                            index)
                                    .fadeIn(
                                        duration: modeTheme
                                                ?.listAnimationDuration ??
                                            const Duration(milliseconds: 400))
                                    .slideY(
                                        begin: 0.2,
                                        curve: modeTheme?.primaryCurve ??
                                            Curves
                                                .easeOut); // Example animation
                              },
                              // Use card margins for spacing, so separator height is 0
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 0),
                            );
                          }
                        }
                      }
                    }
                    // --- Error State ---
                    // Use base state type for check
                    else if (state is BaseListErrorState) {
                      content = Center(
                        child: Padding(
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
                                  style: TextStyle(
                                      color: theme.colorScheme.error)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                // Use the load event builder to retry
                                onPressed: () => _listBloc.add(
                                    widget.loadEventBuilder(forceReload: true)),
                              )
                            ],
                          ),
                        ),
                      );
                    }
                    // --- Initial State Fallback ---
                    else {
                      content =
                          const Center(child: CircularProgressIndicator());
                    }

                    // AnimatedSwitcher for smooth transitions between states
                    return AnimatedSwitcher(
                      duration: modeTheme?.mediumDuration ??
                          const Duration(milliseconds: 300),
                      // Key helps differentiate states, especially list vs. empty/error
                      child: KeyedSubtree(
                          key: ValueKey(state.runtimeType.toString() +
                              (state is BaseListState
                                  ? state.items.length.toString()
                                  : '')),
                          child: content),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: widget.fabHeroTag, // Use provided tag
          onPressed: _navigateToAdd,
          tooltip:
              'Add ${widget.pageTitle.substring(0, widget.pageTitle.length - 1)}', // e.g., "Add Expense"
          // Use themed icon if available
          child: modeTheme != null &&
                  modeTheme.assets
                      .getCommonIcon(AssetKeys.iconAdd, defaultPath: '')
                      .isNotEmpty
              ? SvgPicture.asset(
                  // Provide a fallback asset path from AppAssets
                  modeTheme.assets.getCommonIcon(AssetKeys.iconAdd,
                      defaultPath: AppAssets.elComIconAdd),
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                      theme.floatingActionButtonTheme.foregroundColor ??
                          Colors.white,
                      BlendMode.srcIn))
              : const Icon(Icons.add), // Material Icon Fallback
        ),
      ),
    );
  }
}
