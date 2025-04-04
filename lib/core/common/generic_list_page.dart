// lib/core/common/generic_list_page.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- Type Definitions ---

// Builder for a single list item widget. Receives context, item data, and selection state.
typedef ItemWidgetBuilder<T> = Widget Function(
    BuildContext context, T item, bool isSelected);

// Builder for a table view representation of the items.
typedef TableWidgetBuilder<T> = Widget Function(
    BuildContext context, List<T> items);

// Builder for the empty state UI. Receives context and whether filters are applied.
typedef EmptyStateWidgetBuilder = Widget Function(
    BuildContext context, bool filtersApplied);

// Builder function signature for initiating the filter dialog/sheet.
typedef FilterDialogBuilder = void Function(
    BuildContext context, BaseListState currentState)?;

// Builder for the confirmation dialog before deleting an item.
typedef DeleteConfirmationBuilder<T> = Future<bool> Function(
    BuildContext context, T item);

// Builder to create the specific Delete event for the Bloc.
typedef DeleteEventBuilder<E> = E Function(String id);

// Builder to create the specific Load event for the Bloc.
typedef LoadEventBuilder<E> = E Function({bool forceReload});

// --- GenericListPage Widget ---

/// A reusable scaffold page for displaying lists of items (like expenses, income, accounts).
/// Handles common functionality: loading, errors, refresh, filtering button, optional summary.
/// Item rendering, actions, filtering logic, and FAB are provided by the concrete page.
class GenericListPage<T, B extends Bloc<E, S>, E, S> extends StatefulWidget {
  final String pageTitle;
  final String addRouteName;
  final String itemHeroTagPrefix;
  final String fabHeroTag;
  final bool showSummaryCard;
  final ItemWidgetBuilder<T> itemBuilder;
  final TableWidgetBuilder<T>? tableBuilder;
  final EmptyStateWidgetBuilder emptyStateBuilder;
  final FilterDialogBuilder filterDialogBuilder;
  final DeleteConfirmationBuilder<T> deleteConfirmationBuilder;
  final DeleteEventBuilder<E> deleteEventBuilder;
  final LoadEventBuilder<E> loadEventBuilder;
  final List<Widget>? appBarActions;
  final Widget?
      floatingActionButton; // Use this for custom FABs (like batch mode)

  const GenericListPage({
    super.key,
    required this.pageTitle,
    required this.addRouteName,
    required this.itemBuilder,
    this.tableBuilder,
    required this.emptyStateBuilder,
    this.filterDialogBuilder,
    required this.deleteConfirmationBuilder,
    required this.deleteEventBuilder,
    required this.loadEventBuilder,
    required this.itemHeroTagPrefix,
    required this.fabHeroTag,
    this.showSummaryCard = false,
    this.appBarActions,
    this.floatingActionButton,
  });

  @override
  State<GenericListPage<T, B, E, S>> createState() =>
      _GenericListPageState<T, B, E, S>();
}

class _GenericListPageState<T, B extends Bloc<E, S>, E, S>
    extends State<GenericListPage<T, B, E, S>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final listBloc = BlocProvider.of<B>(context);
      // Check against the BASE initial state type
      if (listBloc.state is BaseListInitialState) {
        log.info(
            "[GenericListPage-${widget.pageTitle}] Bloc is initial, dispatching load event.");
        listBloc.add(widget.loadEventBuilder(forceReload: false));
      }
    });
  }

  Future<void> _refreshList() async {
    log.info(
        "[GenericListPage-${widget.pageTitle}] Pull-to-refresh triggered.");
    try {
      final listBloc = BlocProvider.of<B>(context);
      listBloc.add(widget.loadEventBuilder(forceReload: true));
      await listBloc.stream
          .firstWhere((state) =>
              state is BaseListState<T> || state is BaseListErrorState)
          .timeout(const Duration(seconds: 7), onTimeout: () {
        log.warning(
            "[GenericListPage-${widget.pageTitle}] Refresh stream timed out.");
        return listBloc.state;
      });
      log.info(
          "[GenericListPage-${widget.pageTitle}] Refresh stream finished or timed out.");
    } catch (e, s) {
      log.warning(
          "[GenericListPage-${widget.pageTitle}] Error during refresh stream wait: $e");
    }
  }

  void _navigateToAdd() {
    log.info(
        "[GenericListPage-${widget.pageTitle}] Navigating to Add screen: ${widget.addRouteName}");
    context.pushNamed(widget.addRouteName);
  }

  @override
  Widget build(BuildContext context) {
    log.fine("[GenericListPage-${widget.pageTitle}] Build method called.");
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final modeTheme = context.modeTheme;
    final useTables = modeTheme?.preferDataTableForLists ?? false;
    final uiMode = settingsState.uiMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        actions: [
          // Filter Button
          if (widget.filterDialogBuilder != null)
            BlocBuilder<B, S>(
              builder: (context, state) {
                bool filtersApplied = false;
                BaseListState? baseState;
                if (state is BaseListState<T>) {
                  baseState = state;
                  filtersApplied = baseState.filtersApplied;
                }
                return IconButton(
                    icon: Icon(filtersApplied
                        ? Icons.filter_list_rounded
                        : Icons.filter_list_off_outlined),
                    tooltip: 'Filter ${widget.pageTitle}',
                    onPressed: () {
                      if (baseState != null) {
                        widget.filterDialogBuilder!(context, baseState);
                      } else {
                        log.warning(
                            "[GenericListPage-${widget.pageTitle}] Filter button pressed but state is not loaded. State: ${state.runtimeType}");
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(const SnackBar(
                            content: Text(
                                "Cannot filter while loading or in error state."),
                            duration: Duration(seconds: 2),
                          ));
                      }
                    });
              },
            ),
          // Additional Actions from concrete page
          ...?widget.appBarActions,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        child: Column(
          children: [
            // Optional Summary Card
            if (widget.showSummaryCard) const SummaryCard(),
            if (widget.showSummaryCard) const Divider(height: 1),
            // Main Content Area
            Expanded(
              child: BlocConsumer<B, S>(
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
                  log.fine(
                      "[GenericListPage-${widget.pageTitle}] BlocBuilder building for state: ${state.runtimeType}");
                  Widget content;

                  // Loading State
                  if (state is BaseListLoadingState && !state.isReloading) {
                    content = const Center(child: CircularProgressIndicator());
                  }
                  // Loaded or Reloading State
                  else if (state is BaseListState<T> ||
                      (state is BaseListLoadingState && state.isReloading)) {
                    final BaseListState<T>? loadedState =
                        state is BaseListState<T>
                            ? state
                            : (context.read<B>().state is BaseListState<T>
                                ? context.read<B>().state as BaseListState<T>
                                : null);

                    if (loadedState == null) {
                      content = const Center(
                          child: CircularProgressIndicator()); // Should be rare
                    } else {
                      final items = loadedState.items;
                      final filtersApplied =
                          widget.filterDialogBuilder != null &&
                              loadedState.filtersApplied;

                      // Determine if batch mode is active based on the specific state (handled by concrete page's itemBuilder)
                      // GenericListPage doesn't know about isInBatchEditMode or selectedIds directly.

                      if (items.isEmpty) {
                        content =
                            widget.emptyStateBuilder(context, filtersApplied);
                      } else {
                        // Determine if Table view should be shown
                        bool showTable = uiMode == UIMode.quantum &&
                            useTables &&
                            widget.tableBuilder != null;
                        if (showTable) {
                          content = widget.tableBuilder!(context, items);
                        } else {
                          // List View
                          content = ListView.separated(
                            key: ValueKey(
                                '${widget.itemHeroTagPrefix}_list_${items.length}'), // Key based on item count
                            padding: modeTheme?.pagePadding
                                    .copyWith(top: 8, bottom: 80) ??
                                const EdgeInsets.only(top: 8, bottom: 80),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              // Determine item ID dynamically
                              String itemId = 'unknown_id_$index';
                              try {
                                itemId = (item as dynamic).id;
                              } catch (e) {/* log warning */}

                              // Selection state (isSelected) must be determined by the concrete page's state
                              // and passed into the itemBuilder call below.
                              // For now, we assume false as GenericListPage doesn't know the selection state.
                              final bool isSelected =
                                  false; // THIS NEEDS TO BE DETERMINED BY CONCRETE PAGE

                              // Call the concrete page's item builder, passing the selection state
                              Widget listItem =
                                  widget.itemBuilder(context, item, isSelected);

                              // Wrap with Dismissible
                              return Dismissible(
                                key: Key('${widget.itemHeroTagPrefix}_$itemId'),
                                // Direction depends on batch mode state (determined by concrete page)
                                // For now, assume batch mode is off:
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: theme.colorScheme.errorContainer,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text("Delete",
                                          style: TextStyle(
                                              color: theme
                                                  .colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Icon(Icons.delete_sweep_outlined,
                                          color: theme
                                              .colorScheme.onErrorContainer),
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
                                          '${_getItemTypeName(widget.pageTitle)} deleted.'), // Helper for better message
                                      backgroundColor: Colors.orangeAccent,
                                      duration: const Duration(seconds: 2),
                                    ));
                                },
                                child: listItem,
                              )
                                  .animate(
                                      delay: (modeTheme?.listAnimationDelay ??
                                              50.ms) *
                                          index)
                                  .fadeIn(
                                      duration:
                                          modeTheme?.listAnimationDuration ??
                                              400.ms)
                                  .slideY(
                                      begin: 0.2,
                                      curve: modeTheme?.primaryCurve ??
                                          Curves.easeOut);
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                                    height:
                                        0), // No visual separator by default
                          );
                        }
                      }
                    }
                  }
                  // Error State
                  else if (state is BaseListErrorState) {
                    content = Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: theme.colorScheme.error, size: 60),
                            const SizedBox(height: 16),
                            Text('Error Loading ${widget.pageTitle}',
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(color: theme.colorScheme.error),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text(state.message,
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: theme.colorScheme.error)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                              onPressed: () => context.read<B>().add(
                                  widget.loadEventBuilder(forceReload: true)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.errorContainer,
                                  foregroundColor:
                                      theme.colorScheme.onErrorContainer),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                  // Initial or Unknown State
                  else {
                    content = const Center(child: CircularProgressIndicator());
                  }

                  // Animated Switcher for smooth state transitions
                  return AnimatedSwitcher(
                    duration: modeTheme?.mediumDuration ??
                        const Duration(milliseconds: 300),
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
      // Floating Action Button: Use custom one if provided, otherwise show default Add button
      floatingActionButton: widget.floatingActionButton ??
          FloatingActionButton(
            heroTag: widget.fabHeroTag, // Ensure unique Hero tag
            onPressed: _navigateToAdd,
            tooltip: 'Add ${_getItemTypeName(widget.pageTitle)}',
            child: modeTheme?.assets
                        .getCommonIcon(AssetKeys.iconAdd)
                        .isNotEmpty ??
                    false
                ? SvgPicture.asset(
                    modeTheme!.assets.getCommonIcon(AssetKeys.iconAdd,
                        defaultPath: AppAssets.elComIconAdd), // Use fallback
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                        theme.floatingActionButtonTheme.foregroundColor ??
                            theme.colorScheme
                                .onPrimaryContainer, // Use themed color
                        BlendMode.srcIn))
                : const Icon(Icons.add),
          ),
    );
  }

  // Helper to get singular item name from plural page title
  String _getItemTypeName(String pageTitle) {
    if (pageTitle.toLowerCase().endsWith('s')) {
      return pageTitle.substring(0, pageTitle.length - 1);
    }
    return pageTitle; // Return original if not ending in 's'
  }
}
