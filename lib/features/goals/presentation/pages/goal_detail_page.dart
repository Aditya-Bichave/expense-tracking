// lib/features/goals/presentation/pages/goal_detail_page.dart
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/contribution_list_item.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/log_contribution_sheet.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/goal_contribution_chart.dart'; // Import chart
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
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
  // --- ADDED State for chart/list view ---
  bool _showContributionChart = true;
  // --- END ADD ---

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
    // ... (goal loading logic remains the same) ...
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
      if (mounted) {
        setState(() {
          _error = "Failed to load goal details.";
          _isLoadingGoal = false;
          _isLoadingContributions = false;
        });
      }
    }, (goal) async {
      if (goal == null) {
        log.severe("[GoalDetail] Goal ${widget.goalId} not found.");
        if (mounted) {
          setState(() {
            _error = "Goal not found.";
            _isLoadingGoal = false;
            _isLoadingContributions = false;
          });
        }
      } else {
        loadedGoal = goal;
        if (mounted) {
          setState(() {
            _currentGoal = loadedGoal;
            _isLoadingGoal = false;
          });

          // Check if the goal was newly achieved to play confetti
          if (loadedGoal != null && loadedGoal.isNewlyAchieved) {
            final uiMode = context.read<SettingsBloc>().state.uiMode;
            if (uiMode != UIMode.quantum) {
              log.info(
                  "[GoalDetail] Goal ${widget.goalId} newly achieved! Playing confetti.");
              _confettiController.play();
            }
            // Acknowledge the achievement so it doesn't trigger again
            context
                .read<GoalListBloc>()
                .add(AcknowledgeGoalAchieved(goalId: widget.goalId));
          }
        }
      }
    });

    if (_error != null || _currentGoal == null) {
      return; // Stop if goal loading failed
    }

    // Fetch Contributions
    final contributionsResult = await _getContributionsUseCase(
        GetContributionsParams(goalId: widget.goalId));
    if (!mounted) return;

    contributionsResult.fold((failure) {
      log.warning(
          "[GoalDetail] Failed to load contributions: ${failure.message}");
      setState(() {
        _error = "${_error ?? ""}\nFailed to load contribution history.";
        _isLoadingContributions = false;
      });
    }, (contributions) {
      log.info("[GoalDetail] Loaded ${contributions.length} contributions.");
      // Optimization: Only update state if the list content actually changed
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
    // ... (no change needed) ...
    if (_currentGoal == null) return;
    context.pushNamed(RouteNames.editGoal,
        pathParameters: {'id': _currentGoal!.id}, extra: _currentGoal);
  }

  void _handleArchive(BuildContext context) async {
    // ... (no change needed) ...
    if (_currentGoal == null) return;
    final confirmed = await AppDialogs.showConfirmation(context,
        title: "Confirm Archive",
        content:
            'Archive "${_currentGoal!.name}"? Contributions will be kept, but the goal will be hidden from the active list.',
        confirmText: "Archive",
        confirmColor: Colors.orange[700]);
    if (confirmed == true && context.mounted) {
      context.read<GoalListBloc>().add(ArchiveGoal(goalId: _currentGoal!.id));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.budgetsAndCats,
            extra: {'initialTabIndex': 1}); // Navigate to goals tab
      }
    }
  }

  Future<bool?> _handleDeleteContribution(
      BuildContext context, GoalContribution contribution) async {
    // ... (no change needed) ...
    final settings = context.read<SettingsBloc>().state;
    final confirmed = await AppDialogs.showConfirmation(context,
        title: "Delete Contribution?",
        content:
            "Delete contribution of ${CurrencyFormatter.format(contribution.amount, settings.currencySymbol)} made on ${DateFormatter.formatDate(contribution.date)}?",
        confirmText: "Delete",
        confirmColor: Theme.of(context).colorScheme.error);
    if (confirmed == true && context.mounted) {
      // Use sl directly if context is problematic across async gaps
      final logContribBloc = sl<LogContributionBloc>();
      // Initialize the bloc with the contribution to be deleted
      logContribBloc.add(InitializeContribution(
          goalId: contribution.goalId, initialContribution: contribution));
      logContribBloc.add(const DeleteContribution());
      return true; // Indicate dialog should close
    }
    return false; // Indicate dialog should not close
  }

  Widget _buildProgressIndicatorWidget(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    // ... (no change needed) ...
    final theme = Theme.of(context);
    if (_currentGoal == null) return const SizedBox(height: 90);
    final goal = _currentGoal!;
    final progress = goal.percentageComplete;
    final color =
        goal.isAchieved ? Colors.green.shade600 : theme.colorScheme.primary;
    final backgroundColor =
        theme.colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round());
    final bool isQuantum = uiMode == UIMode.quantum;

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

  // REFINED: Contribution List/Chart Widget
  Widget _buildContributionWidget(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;

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

    return Column(
      children: [
        // --- Toggle Button ---
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CupertinoSlidingSegmentedControl<bool>(
            children: const {
              true: Padding(padding: EdgeInsets.all(8), child: Text('Chart')),
              false: Padding(padding: EdgeInsets.all(8), child: Text('List')),
            },
            groupValue: _showContributionChart,
            onValueChanged: (bool? value) {
              if (value != null) {
                setState(() => _showContributionChart = value);
              }
            },
          ),
        ),
        // --- END Toggle Button ---
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _showContributionChart
              ? KeyedSubtree(
                  // Use key to help AnimatedSwitcher
                  key: const ValueKey('contrib_chart'),
                  child: SizedBox(
                    height: 200, // Fixed height for chart
                    child: GoalContributionChart(contributions: _contributions),
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('contrib_list'),
                  child: _buildContributionList(context, settings),
                ),
        ),
      ],
    );
  }

  // Helper for Contribution List Items (with Drill-Down)
  Widget _buildContributionList(BuildContext context, SettingsState settings) {
    final bool isAether = settings.uiMode == UIMode.aether;
    final modeTheme = context.modeTheme;
    final itemDelay =
        isAether ? (modeTheme?.listAnimationDelay ?? 80.ms) : 50.ms;
    final itemDuration =
        isAether ? (modeTheme?.listAnimationDuration ?? 450.ms) : 300.ms;
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _contributions.length,
      itemBuilder: (ctx, index) {
        final contribution = _contributions[index];
        Widget item = ContributionListItem(
            contribution: contribution, goalId: widget.goalId);

        // --- ADDED: InkWell for Drill Down ---
        item = InkWell(
          onTap: () {
            log.info(
                "[GoalDetail] Tapped contribution item ID: ${contribution.id}");
            showLogContributionSheet(
              context,
              contribution.goalId,
              initialContribution: contribution,
            );
          },
          child: item,
        );
        // --- END ADDED ---

        // Apply animation
        item = item
            .animate(delay: itemDelay * index)
            .fadeIn(duration: itemDuration)
            .slideY(begin: 0.1, curve: Curves.easeOut);

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
  // --- End Contribution Widget ---

  @override
  Widget build(BuildContext context) {
    // ... (rest of build method including loading/error checks remains the same) ...
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final uiMode = settings.uiMode;
    final modeTheme = context.modeTheme;

    if (_isLoadingGoal) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _currentGoal == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error ?? "Goal could not be loaded.",
                      style: TextStyle(color: theme.colorScheme.error)))));
    }

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
                          theme.colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round())),
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
        const SectionHeader(title: "Contribution History"),
        // --- REPLACED List with conditional Chart/List ---
        _buildContributionWidget(context, modeTheme, uiMode),
        // --- END REPLACED ---
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name, overflow: TextOverflow.ellipsis),
        backgroundColor: isAether ? Colors.transparent : null,
        elevation: isAether ? 0 : null,
        actions: [
          if (!goal.isArchived)
            IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _navigateToEdit(context),
                tooltip: "Edit Goal"),
          if (!goal.isArchived)
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
      floatingActionButton: goal.isAchieved || goal.isArchived
          ? null
          : FloatingActionButton.extended(
              heroTag: 'add_contribution_fab',
              icon: const Icon(Icons.add),
              label: const Text("Log Contribution"),
              onPressed: () {
                showLogContributionSheet(context, goal.id);
              },
            ),
    );
  }
}
