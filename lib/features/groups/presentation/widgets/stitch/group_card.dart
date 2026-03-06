import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';

enum GroupStatus { owed, owe, settled }

class GroupCard extends StatelessWidget {
  final String name;
  final String description;
  final String timeAgo;
  final GroupStatus status;
  final String amount;
  final IconData icon;
  final Color iconColor;

  const GroupCard({
    super.key,
    required this.name,
    required this.description,
    required this.timeAgo,
    required this.status,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    Color amountColor;
    String statusText;

    switch (status) {
      case GroupStatus.owed:
        amountColor = kit.colors.primary;
        statusText = 'You are owed';
        break;
      case GroupStatus.owe:
        amountColor = kit.colors.error;
        statusText = 'You owe';
        break;
      case GroupStatus.settled:
        amountColor = kit.colors.textSecondary;
        statusText = 'All settled';
        break;
    }

    return AppCard(
      margin: kit.spacing.vSm,
      padding: kit.spacing.allMd,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BridgeDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: kit.radii.medium,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          kit.spacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: kit.typography.bodyStrong.copyWith(fontSize: 16),
                    ),
                    Text(
                      timeAgo,
                      style: kit.typography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kit.colors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Text(
                  description,
                  style: kit.typography.caption.copyWith(
                    color: kit.colors.textSecondary,
                  ),
                ),
                kit.spacing.gapXs,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Mock avatars
                    Row(
                      children: [
                        _buildAvatar(kit.colors.primary, kit),
                        SizedBox(width: -8),
                        _buildAvatar(kit.colors.secondary, kit),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          statusText,
                          style: kit.typography.caption.copyWith(
                            color: kit.colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          amount,
                          style: kit.typography.bodyStrong.copyWith(
                            fontSize: 16,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, AppKitTheme kit) {
    return Container(
      width: 24,
      height: 24,
      decoration: BridgeDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: kit.colors.surface, width: 2),
      ),
    );
  }
}
