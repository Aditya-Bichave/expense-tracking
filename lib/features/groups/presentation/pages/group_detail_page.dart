import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:expense_tracker/features/group_expenses/presentation/pages/add_group_expense_page.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/group_members_tab.dart';
import 'package:expense_tracker/features/groups/presentation/widgets/stitch/invite_generation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_bottom_sheet.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          create: (context) =>
              sl<GroupExpensesBloc>()..add(LoadGroupExpenses(widget.groupId)),
        ),
        BlocProvider(
          create: (context) =>
              sl<GroupMembersBloc>()..add(LoadGroupMembers(widget.groupId)),
        ),
      ],
      child: Builder(
        builder: (context) {
          final kit = context.kit;
          final groupsState = context.watch<GroupsBloc>().state;
          String groupName = 'Group';
          if (groupsState is GroupsLoaded) {
            try {
              final group = groupsState.groups.firstWhere(
                (g) => g.id == widget.groupId,
              );
              groupName = group.name;
            } catch (_) {
              // Group not found or error, fallback to default name
            }
          }

          return BlocListener<GroupMembersBloc, GroupMembersState>(
            listener: (context, state) {
              if (state is GroupInviteGenerated) {
                Clipboard.setData(ClipboardData(text: state.url));
                AppDialogs.showSuccessSnackbar(
                  context,
                  'Invite link copied to clipboard',
                );
              } else if (state is GroupInviteGenerationError) {
                AppDialogs.showErrorDialog(context, state.message);
              }
            },
            child: BlocBuilder<GroupMembersBloc, GroupMembersState>(
              builder: (context, membersState) {
                bool canAddExpense = false;
                bool isAdmin = false;
                bool canEdit = false;

                if (membersState is GroupMembersLoaded) {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    final currentUser = authState.user;
                    try {
                      final member = membersState.members.firstWhere(
                        (m) => m.userId == currentUser.id,
                      );
                      isAdmin = member.role == GroupRole.admin;
                      // Viewers cannot add, edit, or settle
                      canAddExpense = member.role != GroupRole.viewer;
                      canEdit = member.role != GroupRole.viewer;
                    } catch (_) {}
                  }
                }

                return AppScaffold(
                  appBar: AppNavBar(
                    title: groupName,
                    actions: [
                      if (isAdmin)
                        AppIconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: () => _showInviteSheet(context),
                          tooltip: 'Invite Members',
                        ),
                      AppIconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          if (isAdmin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Group Settings (Admin Only)'),
                              ),
                            );
                          } else {
                            _showGroupInfoDialog(context, groupName);
                          }
                        },
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
                            BlocBuilder<GroupExpensesBloc, GroupExpensesState>(
                              builder: (context, state) {
                                if (state is GroupExpensesLoading) {
                                  return const AppLoadingIndicator();
                                } else if (state is GroupExpensesLoaded) {
                                  if (state.expenses.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No expenses yet.',
                                        style: kit.typography.body,
                                      ),
                                    );
                                  }
                                  return ListView.builder(
                                    itemCount: state.expenses.length,
                                    itemBuilder: (context, index) {
                                      final expense = state.expenses[index];
                                      return AppListTile(
                                        title: Text(expense.title),
                                        trailing: Text(
                                          '\${expense.amount} \${expense.currency}',
                                          style: kit.typography.bodyStrong
                                              .copyWith(
                                                color: kit.colors.textPrimary,
                                              ),
                                        ),
                                        subtitle: Text(
                                          'Paid by \${expense.createdBy}',
                                        ),
                                        onTap: canEdit
                                            ? () {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Edit Expense',
                                                    ),
                                                  ),
                                                );
                                              }
                                            : null,
                                      );
                                    },
                                  );
                                } else if (state is GroupExpensesError) {
                                  return Center(
                                    child: Text(
                                      'Error: \${state.message}',
                                      style: kit.typography.body.copyWith(
                                        color: kit.colors.error,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const GroupMembersTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
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

  void _showGroupInfoDialog(BuildContext context, String groupName) {
    AppDialog.show(
      context: context,
      title: 'Group Info',
      content: 'Name: \$groupName\nRole: Member/Viewer',
      cancelLabel: 'Close',
    );
  }
}
