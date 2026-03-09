import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/groups/domain/entities/simplified_debt.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/group_balances_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_balances/nudge_state.dart';
import 'package:expense_tracker/features/settlements/presentation/widgets/settlement_dialog.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';

class GroupBalancesTab extends StatefulWidget {
  final String groupId;

  const GroupBalancesTab({super.key, required this.groupId});

  @override
  State<GroupBalancesTab> createState() => _GroupBalancesTabState();
}

class _GroupBalancesTabState extends State<GroupBalancesTab> {
  @override
  void initState() {
    super.initState();
    context.read<GroupBalancesBloc>().add(FetchBalances(widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final currentUserId = _getCurrentUserId(context);

    return BlocConsumer<GroupBalancesBloc, GroupBalancesState>(
      listener: (context, state) {
        if (state is GroupBalancesError) {
          AppDialogs.showErrorDialog(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is GroupBalancesLoading) {
          return const Center(child: AppLoadingIndicator());
        } else if (state is GroupBalancesLoaded) {
          final balances = state.balances;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GroupBalancesBloc>().add(
                RefreshBalances(widget.groupId),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSummaryCard(context, kit, balances.myNetBalance),
                kit.spacing.gapLg,
                Text('Simplified Debts', style: kit.typography.title),
                kit.spacing.gapMd,
                if (balances.simplifiedDebts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'You are all settled up!',
                        style: kit.typography.body.copyWith(
                          color: kit.colors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...balances.simplifiedDebts.map(
                    (debt) => _buildDebtTile(context, kit, debt, currentUserId),
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    AppKitTheme kit,
    double myNetBalance,
  ) {
    String title;
    Color color;
    String amountText =
        '${myNetBalance.abs().toStringAsFixed(2)} INR'; // Assume INR for now

    if (myNetBalance < 0) {
      title = 'You owe';
      color = kit.colors.error;
    } else if (myNetBalance > 0) {
      title = 'You are owed';
      color = kit.colors.success;
    } else {
      title = 'You are all settled up';
      color = kit.colors.textSecondary;
      amountText = '';
    }

    return AppCard(
      padding: const EdgeInsets.all(24.0),
      color: kit.colors.surface,
      child: Column(
        children: [
          Text(title, style: kit.typography.title.copyWith(color: color)),
          if (amountText.isNotEmpty) ...[
            kit.spacing.gapSm,
            Text(
              amountText,
              style: kit.typography.display.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtTile(
    BuildContext context,
    AppKitTheme kit,
    SimplifiedDebt debt,
    String? currentUserId,
  ) {
    final bool iOwe = debt.fromUserId == currentUserId;
    final bool iAmOwed = debt.toUserId == currentUserId;

    String title;
    Widget? trailing;

    if (iOwe) {
      title = 'You owe ${debt.toUserName} ${debt.amount.toStringAsFixed(2)}';
      trailing = AppButton(
        variant: UiVariant.primary,
        label: 'Settle Up',
        onPressed: () => _showSettleUpDialog(context, debt),
      );
    } else if (iAmOwed) {
      title = '${debt.fromUserName} owes you ${debt.amount.toStringAsFixed(2)}';
      trailing = BlocConsumer<NudgeBloc, NudgeState>(
        listener: (context, state) {
          if (state is NudgeSuccess && state.userId == debt.fromUserId) {
            AppDialogs.showSuccessSnackbar(context, 'Nudge sent successfully!');
          } else if (state is NudgeFailure && state.userId == debt.fromUserId) {
            AppDialogs.showErrorDialog(context, state.message);
          }
        },
        builder: (context, state) {
          bool isSending =
              state is NudgeSending && state.userId == debt.fromUserId;
          return AppButton(
            variant: UiVariant.secondary,
            label: isSending ? 'Sending...' : 'Nudge',
            onPressed: isSending
                ? null
                : () {
                    context.read<NudgeBloc>().add(
                      SendNudge(groupId: widget.groupId, debt: debt),
                    );
                  },
          );
        },
      );
    } else {
      title =
          '${debt.fromUserName} owes ${debt.toUserName} ${debt.amount.toStringAsFixed(2)}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AppCard(
        child: AppListTile(
          title: Text(title, style: kit.typography.bodyStrong),
          trailing: trailing,
        ),
      ),
    );
  }

  void _showSettleUpDialog(BuildContext context, SimplifiedDebt debt) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: context.read<GroupBalancesBloc>(),
          child: SettlementDialog(
            receiverName: debt.toUserName,
            receiverUpiId: debt.toUserUpi,
            amount: debt.amount,
            currency: 'INR', // Defaulting to INR based on earlier logic
            onSettled: () {
              context.read<GroupBalancesBloc>().add(
                ApplyOptimisticSettlement(
                  fromUserId: debt.fromUserId,
                  toUserId: debt.toUserId,
                  amount: debt.amount,
                ),
              );
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );
  }

  String? _getCurrentUserId(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user.id;
    }
    return null;
  }
}
