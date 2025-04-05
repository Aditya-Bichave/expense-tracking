// lib/features/goals/presentation/pages/goal_detail_page.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_contributions_for_goal.dart'; // To fetch contributions
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart'; // To fetch goal details if needed
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart'; // To archive
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/contribution_list_item.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart'; // Reuse card for header display
import 'package:expense_tracker/features/goals/presentation/widgets/log_contribution_sheet.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/router.dart'; // For AppRouter constants
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart'; // Import confetti
import 'dart:math'; // For confetti random

class GoalDetailPage extends StatefulWidget {
  final String goalId; // Pass ID via path parameter
  final Goal? initialGoal; // Optional: Pass via extra for faster initial load

  const GoalDetailPage({
    super.key,
    required this.goalId,
    this.initialGoal,
  });

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  // UseCases injected or retrieved via sl
  final GetContributionsForGoalUseCase _getContributionsUseCase = sl();
  final GetGoalsUseCase _getGoalsUseCase =
      sl(); // To fetch details if not passed

  Goal? _currentGoal;
  List<GoalContribution> _contributions = [];
  bool _isLoadingGoal = true;
  bool _isLoadingContributions = true;
  String? _error;

  late ConfettiController _confettiController; // For achievement celebration

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.initialGoal; // Use initial data if available
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadData();
    // Listen for changes that might affect this goal or its contributions
    context.read<GoalListBloc>().stream.listen(_handleBlocStateChange);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleBlocStateChange(dynamic state) {
    if (mounted && !_isLoadingGoal) {
      // Avoid reload if already loading
      log.fine("[GoalDetail] Received Bloc update, reloading goal data.");
      _loadData(); // Reload all data on any relevant change for simplicity
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGoal =
          _currentGoal == null; // Only true loading if no initial data
      _isLoadingContributions = true;
      _error = null;
    });

    bool goalAlreadyAchievedBeforeLoad = _currentGoal?.isAchieved ?? false;

    // 1. Fetch/Update Goal Details
    // Try to find updated goal from GoalListBloc first for efficiency
    final goalListState = context.read<GoalListBloc>().state;
    Goal? foundGoal;
    if (goalListState.status == GoalListStatus.success) {
      try {
        foundGoal =
            goalListState.goals.firstWhere((g) => g.id == widget.goalId);
      } catch (e) {
        // Might be archived or deleted
        log.warning(
            "[GoalDetail] Goal ${widget.goalId} not found in GoalListBloc state.");
      }
    }

    // If not found in list state (or state not loaded), fetch individually
    if (foundGoal == null) {
      final goalResult =
          await _getGoalsUseCase(const NoParams()); // This gets active goals
      await goalResult.fold((failure) async {
        // Try fetching archived goals if not found in active
        final archivedResult =
            await sl<GoalRepository>().getGoals(includeArchived: true);
        archivedResult.fold((f) {
          log.severe(
              "[GoalDetail] Failed to load goal details: ${failure.message}");
          if (mounted)
            setState(() {
              _error = "Failed to load goal details.";
              _isLoadingGoal = false;
            });
        }, (allGoals) {
          try {
            foundGoal = allGoals.firstWhere((g) => g.id == widget.goalId);
            log.info("[GoalDetail] Found goal in archived list.");
          } catch (e) {
            log.severe(
                "[GoalDetail] Goal ${widget.goalId} not found even in archived.");
            if (mounted)
              setState(() {
                _error = "Goal not found.";
                _isLoadingGoal = false;
              });
          }
        });
      }, (goals) {
        try {
          foundGoal = goals.firstWhere((g) => g.id == widget.goalId);
        } catch (e) {
          log.warning(
              "[GoalDetail] Goal ${widget.goalId} not found in active goals list state.");
          // It might be archived, try fetching all including archived
          // We handle this in the failure case above now. If it gets here, it means
          // the goal might have been deleted between list load and detail load.
          if (mounted)
            setState(() {
              _error = "Goal not found.";
              _isLoadingGoal = false;
            });
        }
      });
    }

    if (foundGoal == null) {
      // If still null after trying everything, exit loading/show error
      if (mounted && _error == null)
        setState(() {
          _error = "Goal not found.";
          _isLoadingGoal = false;
        });
      return; // Don't proceed if goal cannot be loaded
    }

    if (mounted) {
      setState(() {
        _currentGoal = foundGoal;
        _isLoadingGoal = false;
      });
    }

    // Check for achievement *after* loading the potentially updated goal state
    if (_currentGoal!.isAchieved && !goalAlreadyAchievedBeforeLoad) {
      log.info(
          "[GoalDetail] Goal ${widget.goalId} newly achieved! Playing confetti.");
      _confettiController.play(); // Play celebration
    }

    // 2. Fetch Contributions
    final contributionsResult = await _getContributionsUseCase(
        GetContributionsParams(goalId: widget.goalId));
    if (!mounted) return;

    contributionsResult.fold((failure) {
      log.warning(
          "[GoalDetail] Failed to load contributions: ${failure.message}");
      setState(() {
        _error = (_error ?? "") +
            "\nFailed to load contribution history."; // Append error
        _isLoadingContributions = false;
      });
    }, (contributions) {
      log.info("[GoalDetail] Loaded ${contributions.length} contributions.");
      setState(() {
        _contributions = contributions;
        _isLoadingContributions = false;
      });
    });
  }

  void _navigateToEdit(BuildContext context) {
    if (_currentGoal == null) return;
    log.info("[GoalDetail] Navigate to edit for goal: ${_currentGoal!.name}");
    context.pushNamed(
      RouteNames.editGoal, // Use AppRouter constant
      pathParameters: {'id': _currentGoal!.id},
      extra: _currentGoal!, // Pass the goal object
    );
  }

  void _handleArchive(BuildContext context) async {
    if (_currentGoal == null) return;
    log.info("[GoalDetail] Archive requested for goal: ${_currentGoal!.name}");
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Archive",
      content:
          'Are you sure you want to archive the goal "${_currentGoal!.name}"?\nArchived goals can be viewed later (feature coming soon). Contributions will be kept.',
      confirmText: "Archive",
      confirmColor: Colors.orange[700],
    );
    if (confirmed == true && context.mounted) {
      context.read<GoalListBloc>().add(ArchiveGoal(goalId: _currentGoal!.id));
      if (context.canPop()) context.pop(); // Go back after requesting archive
    }
  }

  Future<bool?> _handleDeleteContribution(
      BuildContext context, GoalContribution contribution) async {
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Delete Contribution?",
      content:
          "Delete contribution of ${CurrencyFormatter.format(contribution.amount, context.read<SettingsBloc>().state.currencySymbol)} made on ${DateFormatter.formatDate(contribution.date)}?",
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed == true && context.mounted) {
      final logContribBloc = sl<LogContributionBloc>();
      // Initialize the bloc with the correct goalId and the contribution to be deleted
      logContribBloc.add(InitializeContribution(
          goalId: contribution.goalId, initialContribution: contribution));
      logContribBloc.add(const DeleteContribution());
      // Rely on DataChangedEvent to trigger reload
      return true; // <<< Allow dismissal
    }
    return false; // <<< Do not dismiss
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;

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
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ));
    }

    final goal = _currentGoal!;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name, overflow: TextOverflow.ellipsis),
        actions: [
          if (!goal.isArchived) // Don't allow edit/archive if already archived
            IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _navigateToEdit(context),
                tooltip: "Edit Goal"),
          if (!goal.isArchived)
            IconButton(
                icon: Icon(goal.status == GoalStatus.active
                    ? Icons.archive_outlined
                    : Icons.unarchive_outlined),
                onPressed: () => _handleArchive(context),
                tooltip: goal.status == GoalStatus.active
                    ? "Archive Goal"
                    : "Unarchive Goal (Not Implemented)"),
          // Optional: Add permanent delete here if desired
        ],
      ),
      // --- Confetti Layer ---
      body: Stack(alignment: Alignment.topCenter, children: [
        ListView(
          padding: const EdgeInsets.all(16.0)
              .copyWith(bottom: 100), // Padding for FAB
          children: [
            // --- Goal Status Card (Reusing GoalCard) ---
            GoalCard(goal: goal, onTap: null), // Make non-tappable here
            const SizedBox(height: 24),

            // --- Contribution History ---
            SectionHeader(
                title: "Contribution History (${_contributions.length})"),
            if (_isLoadingContributions)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_contributions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                    child: Text("No contributions logged yet.",
                        style: theme.textTheme.bodyMedium)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _contributions.length,
                itemBuilder: (ctx, index) {
                  final contribution = _contributions[index];
                  return Dismissible(
                    // Allow deleting contribution by swipe
                    key: Key('contrib_dismiss_${contribution.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                        color: theme.colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete_sweep_outlined,
                            color: theme.colorScheme.onErrorContainer)),
                    confirmDismiss: (_) =>
                        _handleDeleteContribution(context, contribution),
                    child: ContributionListItem(
                      contribution: contribution,
                      goalId: goal.id, // Pass goalId for edit sheet init
                    ),
                  );
                },
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, thickness: 0.5),
              )
          ],
        ),
        // --- Confetti Widget ---
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20,
            gravity: 0.1,
            emissionFrequency: 0.05,
            maxBlastForce: 5,
            minBlastForce: 2,
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
          ? null // No FAB if achieved or archived
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
