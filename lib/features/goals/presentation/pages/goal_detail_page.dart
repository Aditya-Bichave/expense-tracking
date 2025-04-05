// lib/features/goals/presentation/pages/goal_detail_page.dart
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/contribution_list_item.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/log_contribution_sheet.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class GoalDetailPage extends StatefulWidget {
  final String goalId;
  final Goal? initialGoal;

  const GoalDetailPage({
    super.key,
    required this.goalId,
    this.initialGoal,
  });

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  final GetContributionsForGoalUseCase _getContributionsUseCase = sl();
  final GoalRepository _goalRepository = sl();

  Goal? _currentGoal;
  List<GoalContribution> _contributions = [];
  bool _isLoadingGoal = true;
  bool _isLoadingContributions = true;
  String? _error;
  late ConfettiController _confettiController;
  StreamSubscription? _goalListSubscription;

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.initialGoal;
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadData();
    _goalListSubscription =
        context.read<GoalListBloc>().stream.listen(_handleBlocStateChange);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _goalListSubscription?.cancel();
    super.dispose();
  }

  void _handleBlocStateChange(dynamic state) {
    if (mounted && !_isLoadingGoal) {
      log.fine("[GoalDetail] Received Bloc update, reloading detail data.");
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    bool wasLoadingBefore = _isLoadingGoal || _isLoadingContributions;
    if (!wasLoadingBefore) {
      log.fine("[GoalDetail] _loadData potentially refreshing.");
    }

    setState(() {
      _isLoadingGoal = _currentGoal == null;
      _isLoadingContributions = true;
      _error = null;
    });

    bool goalAlreadyAchievedBeforeLoad = _currentGoal?.isAchieved ?? false;

    // Fetch Goal Detail
    final goalResult = await _goalRepository.getGoalById(widget.goalId);
    Goal? loadedGoal;

    await goalResult.fold((failure) async {
      log.severe(
          "[GoalDetail] Failed to load goal details: ${failure.message}");
      if (mounted)
        setState(() {
          _error = "Failed to load goal details.";
          _isLoadingGoal = false;
          _isLoadingContributions = false;
        });
    }, (goal) async {
      if (goal == null) {
        log.severe("[GoalDetail] Goal ${widget.goalId} not found.");
        if (mounted)
          setState(() {
            _error = "Goal not found.";
            _isLoadingGoal = false;
            _isLoadingContributions = false;
          });
      } else {
        loadedGoal = goal;
        if (mounted) {
          bool goalStateChanged =
              !const DeepCollectionEquality().equals(_currentGoal, loadedGoal);
          setState(() {
            _currentGoal = loadedGoal;
            _isLoadingGoal = false;
          });

          final uiMode = context.read<SettingsBloc>().state.uiMode;
          if (_currentGoal!.isAchieved &&
              !goalAlreadyAchievedBeforeLoad &&
              uiMode != UIMode.quantum) {
            log.info(
                "[GoalDetail] Goal ${widget.goalId} newly achieved! Playing confetti.");
            _confettiController.play();
          } else if (!_currentGoal!.isAchieved &&
              goalAlreadyAchievedBeforeLoad) {
            log.info("[GoalDetail] Goal ${widget.goalId} no longer achieved.");
          }
        }
      }
    });

    if (_error != null || _currentGoal == null)
      return; // Stop if goal loading failed

    // Fetch Contributions
    final contributionsResult = await _getContributionsUseCase(
        GetContributionsParams(goalId: widget.goalId));
    if (!mounted) return;

    contributionsResult.fold((failure) {
      log.warning(
          "[GoalDetail] Failed to load contributions: ${failure.message}");
      setState(() {
        _error = (_error ?? "") + "\nFailed to load contribution history.";
        _isLoadingContributions = false;
      });
    }, (contributions) {
      log.info("[GoalDetail] Loaded ${contributions.length} contributions.");
      if (!const DeepCollectionEquality()
          .equals(_contributions, contributions)) {
        setState(() {
          _contributions = contributions;
        });
      }
      setState(() {
        _isLoadingContributions = false;
      });
    });
  }

  void _navigateToEdit(BuildContext context) {
    if (_currentGoal == null) return;
    // Navigate using the correct route name
    context.pushNamed(RouteNames.editGoal,
        pathParameters: {'id': _currentGoal!.id}, extra: _currentGoal);
  }

  void _handleArchive(BuildContext context) async {
    if (_currentGoal == null) return;
    final confirmed = await AppDialogs.showConfirmation(context,
        title: "Confirm Archive",
        content:
            'Archive "${_currentGoal!.name}"? Contributions will be kept, but the goal will be hidden from the active list.',
        confirmText: "Archive",
        confirmColor: Colors.orange[700]);
    if (confirmed == true && context.mounted) {
      context.read<GoalListBloc>().add(ArchiveGoal(goalId: _currentGoal!.id));
      if (context.canPop())
        context.pop();
      else
        context.go(RouteNames.budgetsAndCats, extra: {'initialTabIndex': 2});
    }
  }

  Future<bool?> _handleDeleteContribution(
      BuildContext context, GoalContribution contribution) async {
    final settings = context.read<SettingsBloc>().state;
    final confirmed = await AppDialogs.showConfirmation(context,
        title: "Delete Contribution?",
        content:
            "Delete contribution of ${CurrencyFormatter.format(contribution.amount, settings.currencySymbol)} made on ${DateFormatter.formatDate(contribution.date)}?",
        confirmText: "Delete",
        confirmColor: Theme.of(context).colorScheme.error);
    if (confirmed == true && context.mounted) {
      final logContribBloc = sl<LogContributionBloc>();
      logContribBloc.add(InitializeContribution(
          goalId: contribution.goalId, initialContribution: contribution));
      logContribBloc.add(const DeleteContribution());
      return true; // Indicate dialog should close
    }
    return false; // Indicate dialog should not close
  }

  // Helper for Progress Indicator (REMOVED AETHER TBD)
  Widget _buildProgressIndicatorWidget(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    final theme = Theme.of(context);
    if (_currentGoal == null) return const SizedBox(height: 90);
    final goal = _currentGoal!;
    final progress = goal.percentageComplete;
    final color =
        goal.isAchieved ? Colors.green.shade600 : theme.colorScheme.primary;
    final backgroundColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final bool isQuantum = uiMode == UIMode.quantum;
    // final bool isAether = uiMode == UIMode.aether; // No Aether specific impl

    // Aether specific asset check (Removed)

    // Elemental or Quantum
    final double radius = isQuantum ? 60.0 : 70.0;
    final double lineWidth = isQuantum ? 8.0 : 12.0;
    final TextStyle centerTextStyle = (isQuantum
                ? theme.textTheme.headlineSmall
                : theme.textTheme.headlineMedium)
            ?.copyWith(fontWeight: FontWeight.bold, color: color) ??
        TextStyle(color: color);

    return CircularPercentIndicator(
        radius: radius,
        lineWidth: lineWidth,
        animation: !isQuantum,
        animationDuration: isQuantum ? 0 : 1000,
        percent: progress,
        center: Text("${(progress * 100).toStringAsFixed(0)}%",
            style: centerTextStyle),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: color,
        backgroundColor: backgroundColor);
  }

  // Helper for Contribution List
  Widget _buildContributionListWidget(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final useTable =
        uiMode == UIMode.quantum && modeTheme?.preferDataTableForLists == true;

    if (_isLoadingContributions) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_contributions.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(child: Text("No contributions logged yet.")));
    }

    if (useTable) {
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: theme.dataTableTheme.headingRowHeight,
            dataRowMinHeight: theme.dataTableTheme.dataRowMinHeight,
            dataRowMaxHeight: theme.dataTableTheme.dataRowMaxHeight,
            columnSpacing: theme.dataTableTheme.columnSpacing,
            headingTextStyle: theme.dataTableTheme.headingTextStyle,
            dataTextStyle: theme.dataTableTheme.dataTextStyle,
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Amount'), numeric: true),
              DataColumn(label: Text('Note'))
            ],
            rows: _contributions
                .map((c) => DataRow(
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            showLogContributionSheet(context, c.goalId,
                                initialContribution: c);
                          }
                        },
                        cells: [
                          DataCell(Text(DateFormatter.formatDate(c.date))),
                          DataCell(Text(
                              CurrencyFormatter.format(c.amount, currency),
                              textAlign: TextAlign.end)),
                          DataCell(Text(c.note ?? '',
                              overflow: TextOverflow.ellipsis))
                        ]))
                .toList(),
          ));
    } else {
      final bool isAether = uiMode == UIMode.aether;
      final Duration itemDelay =
          isAether ? (modeTheme?.listAnimationDelay ?? 80.ms) : 50.ms;
      final Duration itemDuration =
          isAether ? (modeTheme?.listAnimationDuration ?? 450.ms) : 300.ms;

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _contributions.length,
        itemBuilder: (ctx, index) {
          final contribution = _contributions[index];
          Widget item = ContributionListItem(
              contribution: contribution, goalId: widget.goalId);
          if (isAether) {
            item = item
                .animate(delay: itemDelay * index)
                .fadeIn(duration: itemDuration)
                .slideY(begin: 0.2, curve: Curves.easeOut);
          } else {
            item = item
                .animate()
                .fadeIn(delay: (itemDelay.inMilliseconds * 0.5 * index).ms);
          }
          return Dismissible(
              key: Key('contrib_dismiss_detail_${contribution.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                  color: theme.colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete_sweep_outlined,
                      color: theme.colorScheme.onErrorContainer)),
              confirmDismiss: (_) =>
                  _handleDeleteContribution(context, contribution),
              child: item);
        },
        separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final uiMode = settings.uiMode;
    final modeTheme = context.modeTheme;

    if (_isLoadingGoal)
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    if (_error != null || _currentGoal == null)
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error ?? "Goal could not be loaded.",
                      style: TextStyle(color: theme.colorScheme.error)))));

    final goal = _currentGoal!;
    final isAether = uiMode == UIMode.aether;
    final String? bgPath = isAether
        ? (Theme.of(context).brightness == Brightness.dark
            ? modeTheme?.assets.mainBackgroundDark
            : modeTheme?.assets.mainBackgroundLight)
        : null;

    Widget mainContent = ListView(
      padding: modeTheme?.pagePadding.copyWith(
              bottom: 100, // Increased padding for FAB
              top: isAether
                  ? (modeTheme.pagePadding.top +
                      kToolbarHeight +
                      MediaQuery.of(context).padding.top)
                  : modeTheme.pagePadding.top) ??
          const EdgeInsets.all(16.0).copyWith(bottom: 100),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _buildProgressIndicatorWidget(context, modeTheme, uiMode),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '${CurrencyFormatter.format(goal.totalSaved, settings.currencySymbol)} / ${CurrencyFormatter.format(goal.targetAmount, settings.currencySymbol)}',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              goal.isAchieved
                  ? 'Goal Achieved!'
                  : '${CurrencyFormatter.format(goal.amountRemaining, settings.currencySymbol)} remaining',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: goal.isAchieved
                      ? Colors.green
                      : theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        if (goal.targetDate != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined,
                      size: 16,
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text('Target: ${DateFormatter.formatDate(goal.targetDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        if (goal.description != null && goal.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(goal.description!,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ),
        SectionHeader(title: "Contribution History (${_contributions.length})"),
        _buildContributionListWidget(context, modeTheme, uiMode),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name, overflow: TextOverflow.ellipsis),
        backgroundColor: isAether ? Colors.transparent : null,
        elevation: isAether ? 0 : null,
        actions: [
          if (!goal.isArchived) // Allow editing only if not archived
            IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _navigateToEdit(context),
                tooltip: "Edit Goal"),
          if (!goal.isArchived) // Allow archiving only if not archived
            IconButton(
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => _handleArchive(context),
                tooltip: "Archive Goal"),
        ],
      ),
      extendBodyBehindAppBar: isAether,
      body: Stack(alignment: Alignment.topCenter, children: [
        if (isAether && bgPath != null && bgPath.isNotEmpty)
          Positioned.fill(child: SvgPicture.asset(bgPath, fit: BoxFit.cover)),
        mainContent,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
            gravity: 0.1,
            emissionFrequency: 0.03,
            maxBlastForce: 7,
            minBlastForce: 3,
            particleDrag: 0.05,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ),
      ]),
      floatingActionButton: goal.isAchieved ||
              goal.isArchived // Disable FAB if achieved or archived
          ? null
          : FloatingActionButton.extended(
              heroTag: 'add_contribution_fab',
              icon: const Icon(Icons.add),
              label: const Text("Add Contribution"),
              onPressed: () {
                showLogContributionSheet(context, goal.id);
              },
            ),
    );
  }
}
