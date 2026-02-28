// lib/features/dashboard/presentation/widgets/stitch/stitch_goals_list.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';

class StitchGoalsList extends StatelessWidget {
  final List<Goal> goals;

  const StitchGoalsList({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();
    final kit = context.kit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kit.spacing.lg,
            vertical: kit.spacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BridgeText(
                'SAVINGS GOALS',
                style: kit.typography.overline.copyWith(
                  color: kit.colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              BridgeText(
                'View All',
                style: kit.typography.caption.copyWith(
                  color: kit.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: kit.spacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: goals.length,
            separatorBuilder: (_, __) => kit.spacing.gapMd,
            itemBuilder: (context, index) =>
                _buildGoalCard(context, goals[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    final kit = context.kit;
    final currencySymbol = context.read<SettingsBloc>().state.currencySymbol;
    final progress =
        (goal.targetAmount > 0 ? (goal.totalSaved / goal.targetAmount) : 0.0)
            .clamp(0.0, 1.0);
    final percent = (progress * 100).toInt().clamp(0, 100);

    return SizedBox(
      width: 140,
      child: AppCard(
        margin: const EdgeInsets.only(),
        padding: kit.spacing.allMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.flag, color: kit.colors.primary, size: 20),
                BridgeText(
                  '$percent%',
                  style: kit.typography.caption.copyWith(
                    color: kit.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            kit.spacing.gapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BridgeText(
                  goal.name,
                  style: kit.typography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                BridgeText(
                  '${CurrencyFormatter.format(goal.totalSaved, currencySymbol)} / ${CurrencyFormatter.format(goal.targetAmount, currencySymbol)}',
                  style: kit.typography.caption.copyWith(
                    fontSize: 10,
                    color: kit.colors.textSecondary,
                  ),
                ),
              ],
            ),
            kit.spacing.gapSm,
            ClipRRect(
              borderRadius: kit.radii.small,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: kit.colors.surfaceContainer,
                color: kit.colors.primary,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
