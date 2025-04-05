// lib/features/goals/presentation/widgets/contribution_list_item.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/log_contribution_sheet.dart'; // To show edit sheet
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContributionListItem extends StatelessWidget {
  final GoalContribution contribution;
  final String goalId; // Needed to re-initialize sheet for edit

  const ContributionListItem({
    super.key,
    required this.contribution,
    required this.goalId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;

    return ListTile(
      // Consider using AppCard as base later if needed
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.tertiaryContainer,
        foregroundColor: theme.colorScheme.onTertiaryContainer,
        child: const Icon(Icons.arrow_upward_rounded,
            size: 20), // Simple contribution icon
      ),
      title: Text(CurrencyFormatter.format(contribution.amount, currency)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormatter.formatDate(contribution.date)),
          if (contribution.note != null && contribution.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                contribution.note!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        tooltip: 'Edit Contribution',
        onPressed: () {
          // Show the sheet again, passing the initial contribution for editing
          showLogContributionSheet(
            context,
            goalId,
            initialContribution: contribution,
          );
        },
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 0, vertical: 4), // Adjust padding
      visualDensity: VisualDensity.compact,
    );
  }
}
