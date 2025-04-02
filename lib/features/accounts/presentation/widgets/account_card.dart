import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

class AccountCard extends StatelessWidget {
  final AssetAccount account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);

    // Determine color based on balance, using theme colors
    final balanceColor = account.currentBalance >= 0
        ? theme.colorScheme.primary // Or Colors.green.shade700
        : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      clipBehavior:
          Clip.antiAlias, // Ensures ink splash stays within card bounds
      child: InkWell(
        // Make the whole card tappable
        onTap: onTap,
        child: Padding(
          // Add padding inside InkWell
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Icon with themed background
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(account.iconData,
                    size: 24, color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 16.0),
              // Name and Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                    Text(account.typeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              // Balance
              Text(
                CurrencyFormatter.format(
                    account.currentBalance, currencySymbol),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
