import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    Color amountColor;
    String statusText;

    switch (status) {
      case GroupStatus.owed:
        amountColor = theme.colorScheme.primary;
        statusText = 'You are owed';
        break;
      case GroupStatus.owe:
        amountColor = theme.colorScheme.error;
        statusText = 'You owe';
        break;
      case GroupStatus.settled:
        amountColor = theme.colorScheme.onSurfaceVariant;
        statusText = 'All settled';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(timeAgo, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
                  ],
                ),
                Text(description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Mock avatars
                    Row(
                      children: [
                        _buildAvatar(Colors.blue),
                        const SizedBox(width: -8),
                        _buildAvatar(Colors.red),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(statusText, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                        Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor)),
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

  Widget _buildAvatar(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
