// lib/features/dashboard/presentation/widgets/stitch/stitch_quick_actions.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

class StitchQuickActions extends StatelessWidget {
  const StitchQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: kit.spacing.lg,
        vertical: kit.spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BridgeText(
            'QUICK ACTIONS',
            style: kit.typography.overline.copyWith(
              color: kit.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          kit.spacing.gapMd,
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  context,
                  Icons.add_circle,
                  'Expense',
                  true,
                  () => context.pushNamed(RouteNames.addTransaction),
                ),
              ),
              kit.spacing.gapMd,
              Expanded(
                child: _buildActionBtn(
                  context,
                  Icons.payments,
                  'Income',
                  false,
                  () => context.pushNamed(RouteNames.addTransaction),
                ),
              ), // Could pass initial type
              kit.spacing.gapMd,
              Expanded(
                child: _buildActionBtn(
                  context,
                  Icons.group_add,
                  'Group',
                  false,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  },
                ),
              ), // No route for Add Group yet?
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    IconData icon,
    String label,
    bool isPrimary,
    VoidCallback onTap,
  ) {
    final kit = context.kit;
    final bgColor = isPrimary
        ? kit.colors.primary
        : kit.colors.surfaceContainer;
    final contentColor = isPrimary
        ? kit.colors.onPrimary
        : kit.colors.textPrimary;

    return Material(
      color: bgColor,
      borderRadius: kit.radii.medium,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: kit.spacing.vLg,
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(icon, color: contentColor),
              kit.spacing.gapSm,
              BridgeText(
                label,
                style: kit.typography.labelSmall.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
