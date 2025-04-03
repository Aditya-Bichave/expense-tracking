// lib/features/accounts/presentation/widgets/account_card.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG
import 'package:expense_tracker/core/assets/app_assets.dart'; // Import asset catalog

class AccountCard extends StatelessWidget {
  final AssetAccount account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  // Helper to select the correct icon based on UI mode
  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    IconData defaultIconData =
        account.iconData; // Fallback Material icon from entity
    String? svgPath;
    // Use account.type.name (e.g., 'bank', 'cash') as the key
    String accountTypeKey = account.type.name.toLowerCase();

    if (modeTheme != null) {
      // Try to get SVG path from theme extension based on account type name
      svgPath = modeTheme.assets.getCategoryIcon(
          // Using category map for account types too
          accountTypeKey,
          defaultPath:
              '' // No default SVG path needed here, will fallback to IconData
          );
      if (svgPath.isEmpty) svgPath = null; // Treat empty string as no SVG found
    }

    if (svgPath != null) {
      // log.debug("Using SVG path for $accountTypeKey: $svgPath");
      return SvgPicture.asset(
        svgPath, // Path comes from theme config
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
            theme.colorScheme.onSecondaryContainer, // Use themed color
            BlendMode.srcIn),
      );
    } else {
      // Fallback to Material Icon defined in AssetAccount entity
      // log.debug("Using default Material Icon for $accountTypeKey");
      return Icon(
        defaultIconData,
        size: 24,
        color: theme.colorScheme.onSecondaryContainer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    final balanceColor = account.currentBalance >= 0
        ? (modeTheme?.incomeGlowColor ??
            theme.colorScheme.primary) // Use income glow/primary for positive
        : (modeTheme?.expenseGlowColor ??
            theme.colorScheme.error); // Use expense glow/error for negative

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: theme.cardTheme.margin,
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: theme.listTileTheme.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                child: _buildIcon(context, modeTheme), // Use helper for icon
              ),
              SizedBox(width: theme.listTileTheme.horizontalTitleGap ?? 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                    Text(account.typeName, // Display type name from entity
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
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
