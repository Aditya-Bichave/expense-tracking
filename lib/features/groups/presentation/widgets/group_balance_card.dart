import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';

class GroupBalanceCard extends StatelessWidget {
  final double netBalance;

  const GroupBalanceCard({super.key, required this.netBalance});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final isOwed = netBalance > 0;
    final isOwe = netBalance < 0;
    final isSettled = netBalance == 0;

    String text;
    Color color;

    if (isSettled) {
      text = "You are settled up";
      color = kit.colors.textSecondary;
    } else if (isOwed) {
      text = "You are owed \$${netBalance.abs().toStringAsFixed(2)}";
      color = kit.colors.success;
    } else {
      text = "You owe \$${netBalance.abs().toStringAsFixed(2)}";
      color = kit.colors.danger;
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Balance",
                  style: kit.typography.labelLarge.copyWith(
                    color: kit.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: kit.typography.title.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              isSettled
                  ? Icons.check_circle_outline
                  : (isOwed ? Icons.arrow_upward : Icons.arrow_downward),
              color: color,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
