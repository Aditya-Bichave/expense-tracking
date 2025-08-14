// lib/features/goals/presentation/pages/goal_detail_page.dart
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
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/contribution_list/contribution_list_bloc.dart';
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

  const GoalDetailPage({super.key, required this.goalId});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late ConfettiController _confettiController;
  bool _showContributionChart = true;
  bool _wasAchieved = false;
  late final ContributionListBloc _contributionBloc;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _contributionBloc = sl<ContributionListBloc>(param1: widget.goalId)
      ..add(const LoadContributions());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _contributionBloc.close();
    super.dispose();
  }

  void _navigateToEdit(BuildContext context, Goal goal) {
    context.pushNamed(
      RouteNames.editGoal,
      pathParameters: {'id': goal.id},
      extra: goal,
    );
  }

  void _handleArchive(BuildContext context, Goal goal) async {
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Archive",
      content:
          'Archive "${goal.name}"? Contributions will be kept, but the goal will be hidden from the active list.',
      confirmText: "Archive",
      confirmColor: Colors.orange[700],
    );
    if (confirmed == true && context.mounted) {
      context.read<GoalListBloc>().add(ArchiveGoal(goalId: goal.id));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          RouteNames.budgetsAndCats,
          extra: {'initialTabIndex': 1},
        ); // Navigate to goals tab
      }
    }
  }

  Future<bool?> _handleDeleteContribution(
    BuildContext context,
    GoalContribution contribution,
  ) async {
    // ... (no change needed) ...
    final settings = context.read<SettingsBloc>().state;
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Delete Contribution?",
      content:
          "Delete contribution of ${CurrencyFormatter.format(contribution.amount, settings.currencySymbol)} made on ${DateFormatter.formatDate(contribution.date)}?",
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed == true && context.mounted) {
      // Use sl directly if context is problematic across async gaps
      final logContribBloc = sl<LogContributionBloc>();
      // Initialize the bloc with the contribution to be deleted
      logContribBloc.add(
        InitializeContribution(
          goalId: contribution.goalId,
          initialContribution: contribution,
        ),
      );
      logContribBloc.add(const DeleteContribution());
      return true; // Indicate dialog should close
    }
    return false; // Indicate dialog should not close
  }

  Widget _buildProgressIndicatorWidget(
    BuildContext context,
    Goal goal,
    AppModeTheme? modeTheme,
    UIMode uiMode,
  ) {
    final theme = Theme.of(context);
    final progress = goal.percentageComplete;
    final color = goal.isAchieved
        ? Colors.green.shade600
        : theme.colorScheme.primary;
    final backgroundColor = theme.colorScheme.surfaceContainerHighest
        .withOpacity(0.5);
    final bool isQuantum = uiMode == UIMode.quantum;

    final double radius = isQuantum ? 60.0 : 70.0;
    final double lineWidth = isQuantum ? 8.0 : 12.0;
    final TextStyle centerTextStyle =
        (isQuantum
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
      center: Text(
        "${(progress * 100).toStringAsFixed(0)}%",
        style: centerTextStyle,
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor: backgroundColor,
    );
  }

  // REFINED: Contribution List/Chart Widget
  Widget _buildContributionWidget(
    BuildContext context,
    List<GoalContribution> contributions,
    ContributionListStatus status,
    AppModeTheme? modeTheme,
    UIMode uiMode,
  ) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;

    if (status == ContributionListStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (contributions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text("No contributions logged yet.")),
      );
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
                  key: const ValueKey('contrib_chart'),
                  child: SizedBox(
                    height: 200,
                    child: GoalContributionChart(contributions: contributions),
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('contrib_list'),
                  child: _buildContributionList(
                    context,
                    settings,
                    contributions,
                  ),
                ),
        ),
      ],
    );
  }

  // Helper for Contribution List Items (with Drill-Down)
  Widget _buildContributionList(
    BuildContext context,
    SettingsState settings,
    List<GoalContribution> contributions,
  ) {
    final bool isAether = settings.uiMode == UIMode.aether;
    final modeTheme = context.modeTheme;
    final itemDelay = isAether
        ? (modeTheme?.listAnimationDelay ?? 80.ms)
        : 50.ms;
    final itemDuration = isAether
        ? (modeTheme?.listAnimationDuration ?? 450.ms)
        : 300.ms;
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contributions.length,
      itemBuilder: (ctx, index) {
        final contribution = contributions[index];
        Widget item = ContributionListItem(
          contribution: contribution,
          goalId: widget.goalId,
        );

        // --- ADDED: InkWell for Drill Down ---
        item = InkWell(
          onTap: () {
            log.info(
              "[GoalDetail] Tapped contribution item ID: ${contribution.id}",
            );
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
            child: Icon(
              Icons.delete_sweep_outlined,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          confirmDismiss: (_) =>
              _handleDeleteContribution(context, contribution),
          child: item,
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
    );
  }
  // --- End Contribution Widget ---

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contributionBloc,
      child: BlocConsumer<GoalListBloc, GoalListState>(
        listenWhen: (prev, curr) {
          final prevGoal = prev.goals.firstWhereOrNull(
            (g) => g.id == widget.goalId,
          );
          final currGoal = curr.goals.firstWhereOrNull(
            (g) => g.id == widget.goalId,
          );
          return prevGoal?.isAchieved != currGoal?.isAchieved;
        },
        listener: (context, state) {
          final goal = state.goals.firstWhereOrNull(
            (g) => g.id == widget.goalId,
          );
          if (goal != null && goal.isAchieved && !_wasAchieved) {
            _wasAchieved = true;
            final uiMode = context.read<SettingsBloc>().state.uiMode;
            if (uiMode != UIMode.quantum) {
              _confettiController.play();
            }
          } else if (goal != null && !goal.isAchieved) {
            _wasAchieved = false;
          }
        },
        builder: (context, goalListState) {
          final theme = Theme.of(context);
          final settings = context.watch<SettingsBloc>().state;
          final uiMode = settings.uiMode;
          final modeTheme = context.modeTheme;

          final goal = goalListState.goals.firstWhereOrNull(
            (g) => g.id == widget.goalId,
          );
          if (goal == null) {
            if (goalListState.status == GoalListStatus.loading ||
                goalListState.status == GoalListStatus.initial) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Text(
                  'Goal not found.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final contributionState = context.watch<ContributionListBloc>().state;
          final contributions = contributionState.contributions;

          final isAether = uiMode == UIMode.aether;
          final String? bgPath = isAether
              ? (Theme.of(context).brightness == Brightness.dark
                    ? modeTheme?.assets.mainBackgroundDark
                    : modeTheme?.assets.mainBackgroundLight)
              : null;

          Widget mainContent = ListView(
            padding:
                modeTheme?.pagePadding.copyWith(
                  bottom: 100,
                  top: isAether
                      ? (modeTheme.pagePadding.top +
                            kToolbarHeight +
                            MediaQuery.of(context).padding.top)
                      : modeTheme.pagePadding.top,
                ) ??
                const EdgeInsets.all(16.0).copyWith(bottom: 100),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: _buildProgressIndicatorWidget(
                    context,
                    goal,
                    modeTheme,
                    uiMode,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '${CurrencyFormatter.format(goal.totalSaved, settings.currencySymbol)} / ${CurrencyFormatter.format(goal.targetAmount, settings.currencySymbol)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                          : theme.colorScheme.onSurfaceVariant,
                    ),
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
                        Icon(
                          Icons.flag_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.7,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${DateFormatter.formatDate(goal.targetDate!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (goal.description != null && goal.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    goal.description!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SectionHeader(title: 'Contribution History'),
              _buildContributionWidget(
                context,
                contributions,
                contributionState.status,
                modeTheme,
                uiMode,
              ),
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
                    onPressed: () => _navigateToEdit(context, goal),
                    tooltip: 'Edit Goal',
                  ),
                if (!goal.isArchived)
                  IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    onPressed: () => _handleArchive(context, goal),
                    tooltip: 'Archive Goal',
                  ),
              ],
            ),
            extendBodyBehindAppBar: isAether,
            body: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (isAether && bgPath != null && bgPath.isNotEmpty)
                  Positioned.fill(
                    child: SvgPicture.asset(bgPath, fit: BoxFit.cover),
                  ),
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
                      Colors.purple,
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: goal.isAchieved || goal.isArchived
                ? null
                : FloatingActionButton.extended(
                    heroTag: 'add_contribution_fab',
                    icon: const Icon(Icons.add),
                    label: const Text('Log Contribution'),
                    onPressed: () {
                      showLogContributionSheet(context, goal.id);
                    },
                  ),
          );
        },
      ),
    );
  }
}
