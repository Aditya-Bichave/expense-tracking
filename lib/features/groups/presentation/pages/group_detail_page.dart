import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_event.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_state.dart';
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/group_balance_card.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_members_tab.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/invite_generation_sheet.dart';
import 'package:expense_tracker/ui_bridge/bridge_bottom_sheet.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<GroupExpensesBloc>()..add(LoadGroupExpenses(widget.groupId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<GroupMembersBloc>()..add(LoadGroupMembers(widget.groupId)),
        ),
      ],
      child: BlocListener<GroupMembersBloc, GroupMembersState>(
        listenWhen: (previous, current) =>
            previous.action != current.action ||
            previous.message != current.message ||
            previous.inviteUrl != current.inviteUrl,
        listener: _handleGroupMemberAction,
        child: Builder(
          builder: (context) {
            final kit = context.kit;
            final group = _currentGroup(context);
            final membersState = context.watch<GroupMembersBloc>().state;
            final currentMember = _currentMember(context, membersState.members);
            final isAdmin = currentMember?.role == GroupRole.admin;
            final canAddExpense =
                currentMember != null && currentMember.role != GroupRole.viewer;
            final canEditExpenses = canAddExpense;

            return AppScaffold(
              appBar: AppNavBar(
                title: group?.name ?? 'Group',
                actions: [
                  if (isAdmin)
                    AppIconButton(
                      key: const ValueKey('button_groupDetail_invite'),
                      icon: const Icon(Icons.person_add),
                      onPressed: () => _showInviteSheet(context),
                      tooltip: 'Invite Members',
                    ),
                  AppIconButton(
                    key: const ValueKey('button_groupDetail_settings'),
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showGroupActionsSheet(
                      context,
                      group,
                      currentMember,
                      membersState.members,
                    ),
                    tooltip: 'Group Settings',
                  ),
                ],
              ),
              floatingActionButton: canAddExpense
                  ? AppFAB(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<GroupExpensesBloc>(),
                              child: AddGroupExpensePage(
                                groupId: widget.groupId,
                                currency: group?.currency ?? 'USD',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                    )
                  : null,
              body: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Expenses'),
                      Tab(text: 'Members'),
                    ],
                    labelColor: kit.colors.primary,
                    unselectedLabelColor: kit.colors.textSecondary,
                    indicatorColor: kit.colors.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExpensesTab(context, group, canEditExpenses),
                        GroupMembersTab(groupId: widget.groupId),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpensesTab(
    BuildContext context,
    GroupEntity? group,
    bool canEditExpenses,
  ) {
    final kit = context.kit;

    return BlocBuilder<GroupExpensesBloc, GroupExpensesState>(
      builder: (context, state) {
        if (state is GroupExpensesLoading) {
          return const AppLoadingIndicator();
        }

        if (state is GroupExpensesError) {
          return Center(
            child: Padding(
              padding: kit.spacing.allLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: kit.typography.body.copyWith(
                      color: kit.colors.error,
                    ),
                  ),
                  kit.spacing.gapLg,
                  ElevatedButton(
                    onPressed: () {
                      context.read<GroupExpensesBloc>().add(
                        LoadGroupExpenses(widget.groupId),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! GroupExpensesLoaded) {
          return const SizedBox.shrink();
        }

        final currentUser = context.read<AuthBloc>().state is AuthAuthenticated
            ? (context.read<AuthBloc>().state as AuthAuthenticated).user
            : null;

        double netBalance = 0;
        if (currentUser != null) {
          for (final expense in state.expenses) {
            if (expense.createdBy == currentUser.id) {
              netBalance += expense.amount;
            }
            final userSplit = expense.splits.firstWhereOrNull(
              (split) => split.userId == currentUser.id,
            );
            if (userSplit != null) {
              netBalance -= userSplit.amount;
            }
          }
        }

        return Column(
          children: [
            if (currentUser != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: GroupBalanceCard(netBalance: netBalance),
              ),
            Expanded(
              child: state.expenses.isEmpty
                  ? Center(
                      child: Text(
                        'No expenses yet.',
                        style: kit.typography.body,
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.expenses.length,
                      itemBuilder: (context, index) {
                        final expense = state.expenses[index];
                        return AppListTile(
                          key: ValueKey('tile_groupExpense_${expense.id}'),
                          title: Text(expense.title),
                          subtitle: Text('Paid by ${expense.createdBy}'),
                          trailing: Text(
                            '${expense.amount.toStringAsFixed(2)} ${group?.currency ?? expense.currency}',
                            style: kit.typography.bodyStrong.copyWith(
                              color: kit.colors.textPrimary,
                            ),
                          ),
                          onTap: canEditExpenses
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<GroupExpensesBloc>(), child: AddGroupExpensePage(groupId: widget.groupId, currency: group?.currency ?? 'USD', initialExpense: expense)))

//
                                  );
                                }
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  GroupEntity? _currentGroup(BuildContext context) {
    final groupsState = context.watch<GroupsBloc>().state;
    if (groupsState is! GroupsLoaded) {
      return null;
    }
    return groupsState.groups.firstWhereOrNull(
      (group) => group.id == widget.groupId,
    );
  }

  GroupMember? _currentMember(BuildContext context, List<GroupMember> members) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return null;
    }
    return members.firstWhereOrNull(
      (member) => member.userId == authState.user.id,
    );
  }

  void _handleGroupMemberAction(BuildContext context, GroupMembersState state) {
    switch (state.action) {
      case GroupMembersAction.inviteGenerated:
        if (state.inviteUrl != null) {
          Clipboard.setData(ClipboardData(text: state.inviteUrl!));
          AppDialogs.showSuccessSnackbar(
            context,
            state.message ?? 'Invite link copied to clipboard',
          );
        }
        break;
      case GroupMembersAction.memberRoleUpdated:
      case GroupMembersAction.memberRemoved:
        if (state.message != null) {
          AppDialogs.showSuccessSnackbar(context, state.message!);
        }
        break;
      case GroupMembersAction.leftGroup:
      case GroupMembersAction.deletedGroup:
        if (state.message != null) {
          AppDialogs.showSuccessSnackbar(context, state.message!);
        }
        context.go(RouteNames.groups);
        break;
      case GroupMembersAction.failed:
        if (state.message != null) {
          AppDialogs.showErrorDialog(context, state.message!);
        }
        break;
      case GroupMembersAction.none:
      case GroupMembersAction.generatingInvite:
      case GroupMembersAction.updatingRole:
      case GroupMembersAction.removingMember:
      case GroupMembersAction.leavingGroup:
      case GroupMembersAction.deletingGroup:
        break;
    }
  }

  void _showInviteSheet(BuildContext context) {
    bridgeShowModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => InviteGenerationSheet(
        onGenerate: (role, expiry, limit) {
          context.read<GroupMembersBloc>().add(
            GenerateInviteLink(
              groupId: widget.groupId,
              role: role,
              expiryDays: expiry,
              maxUses: limit,
            ),
          );
        },
      ),
    );
  }

  void _showGroupActionsSheet(
    BuildContext context,
    GroupEntity? group,
    GroupMember? currentMember,
    List<GroupMember> members,
  ) {
    final kit = context.kit;
    final isAdmin = currentMember?.role == GroupRole.admin;
    final adminCount = members
        .where((member) => member.role == GroupRole.admin)
        .length;
    final isSoleAdmin = isAdmin && adminCount == 1;

    bridgeShowModalBottomSheet(
      context: context,
      backgroundColor: kit.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: kit.radii.sheet),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAdmin && group != null)
                AppListTile(
                  key: const ValueKey('button_groupDetail_edit'),
                  leading: Icon(Icons.edit, color: kit.colors.textPrimary),
                  title: const Text('Edit Group'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.goNamed(
                      RouteNames.groupEdit,
                      pathParameters: {'id': widget.groupId},
                      extra: group,
                    );
                  },
                ),
              AppListTile(
                key: const ValueKey('button_groupDetail_leave'),
                leading: Icon(Icons.logout, color: kit.colors.textPrimary),
                title: Text(
                  isSoleAdmin ? 'Delete Group and Leave' : 'Leave Group',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmLeaveOrDelete(context, currentMember, isSoleAdmin);
                },
              ),
              if (isAdmin)
                AppListTile(
                  key: const ValueKey('button_groupDetail_delete'),
                  leading: Icon(Icons.delete_forever, color: kit.colors.error),
                  title: Text(
                    'Delete Group',
                    style: kit.typography.body.copyWith(
                      color: kit.colors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteGroup(context);
                  },
                ),
              if (!isAdmin)
                AppListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: kit.colors.textSecondary,
                  ),
                  title: const Text('View Group Info'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showGroupInfoDialog(
                      context,
                      groupName: group?.name ?? 'Group',
                      role: currentMember?.role.value ?? 'member',
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLeaveOrDelete(
    BuildContext context,
    GroupMember? currentMember,
    bool isSoleAdmin,
  ) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || currentMember == null) {
      AppDialogs.showErrorDialog(
        context,
        'You must be logged in to manage this group.',
      );
      return;
    }

    final title = isSoleAdmin ? 'Delete group?' : 'Leave group?';
    final content = isSoleAdmin
        ? 'You are the last admin. Leaving this group will permanently delete it for everyone.'
        : 'Are you sure you want to leave this group?';

    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: title,
      content: content,
      confirmText: isSoleAdmin ? 'Delete Group' : 'Leave Group',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed != true) {
      return;
    }

    if (isSoleAdmin) {
      context.read<GroupMembersBloc>().add(
        DeleteCurrentGroup(groupId: widget.groupId),
      );
    } else {
      context.read<GroupMembersBloc>().add(
        LeaveCurrentGroup(groupId: widget.groupId, userId: authState.user.id),
      );
    }
  }

  void _confirmDeleteGroup(BuildContext context) async {
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: 'Delete group?',
      content:
          'This permanently removes the group, members, invites, and group expenses.',
      confirmText: 'Delete Group',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed != true) {
      return;
    }
    context.read<GroupMembersBloc>().add(
      DeleteCurrentGroup(groupId: widget.groupId),
    );
  }

  void _showGroupInfoDialog(
    BuildContext context, {
    required String groupName,
    required String role,
  }) {
    AppDialog.show(
      context: context,
      title: 'Group Info',
      content: 'Name: $groupName\nRole: ${role.toUpperCase()}',
      cancelLabel: 'Close',
    );
  }
}
