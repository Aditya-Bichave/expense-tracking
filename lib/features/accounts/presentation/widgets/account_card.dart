import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For aether icons maybe

class AccountCard extends StatelessWidget {
  final AssetAccount account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  // --- Placeholder for Aether Icons ---
  IconData _getAetherAccountIcon(AssetType type, String themeId) {
    // TODO: Implement logic to return specific Aether icons based on themeId
    // Example:
    // if (themeId == AppTheme.aetherGardenThemeId) {
    //   switch(type) {
    //      case AssetType.bank: return Icons.eco; // Placeholder
    //      ...
    //   }
    // } else if (themeId == AppTheme.aetherConstellationThemeId) { ... }
    return account.iconData; // Fallback to default elemental icon
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final uiMode = settingsState.uiMode;
    final theme = Theme.of(context);

    // Determine styles based on UI mode
    final bool isQuantum = uiMode == UIMode.quantum;
    final bool isAether = uiMode == UIMode.aether;
    final EdgeInsets cardPadding = isQuantum
        ? const EdgeInsets.symmetric(
            horizontal: 10.0, vertical: 6.0) // Quantum: Tighter
        : const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 12.0); // Elemental/Aether: Default
    final double iconSize = isQuantum ? 20 : 24;
    final double spacing = isQuantum ? 12.0 : 16.0;
    final TextStyle? titleStyle = isQuantum
        ? theme.textTheme.titleSmall // Quantum: Smaller title
        : theme.textTheme.titleMedium;
    final TextStyle? balanceStyle = isQuantum
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final IconData displayIcon = isAether
        ? _getAetherAccountIcon(
            account.type, settingsState.selectedThemeIdentifier)
        : account.iconData; // Use standard icon for Elemental/Quantum

    // Determine balance color based on theme
    final balanceColor = account.currentBalance >= 0
        ? (isQuantum
            ? theme.colorScheme.onSurface
            : theme.colorScheme.primary) // Black/White in Quantum
        : theme.colorScheme.error;

    return Card(
      // Card Theme handles margin, elevation, shape based on mode
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: cardPadding, // Apply conditional padding
          child: Row(
            children: [
              // Icon with themed background
              CircleAvatar(
                // Aether might have custom background/shape later
                backgroundColor: isAether
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.secondaryContainer,
                child: Icon(displayIcon,
                    size: iconSize,
                    color: isAether
                        ? theme.colorScheme.onTertiaryContainer
                        : theme.colorScheme.onSecondaryContainer),
              ),
              SizedBox(width: spacing),
              // Name and Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style: titleStyle, overflow: TextOverflow.ellipsis),
                    if (!isQuantum) // Only show type in non-quantum modes for density
                      Text(account.typeName,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              SizedBox(width: spacing),
              // Balance
              Text(
                CurrencyFormatter.format(
                    account.currentBalance, currencySymbol),
                style: balanceStyle?.copyWith(color: balanceColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
