import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG

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
    IconData defaultIconData = account.iconData; // Fallback Material icon
    String? svgPath;

    if (modeTheme != null) {
      // Try to get SVG path from theme extension based on account type name
      svgPath = modeTheme.assets.getCategoryIcon(
          account.type.name, // e.g., 'bank', 'cash'
          defaultPath:
              '' // No default SVG path needed here, will fallback to IconData
          );
      if (svgPath.isEmpty) svgPath = null; // Treat empty string as no SVG found
    }

    if (svgPath != null) {
      // Use SVG if path is available
      return SvgPicture.asset(
        svgPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
            theme.colorScheme.onSecondaryContainer, // Use themed color
            BlendMode.srcIn),
      );
    } else {
      // Fallback to Material Icon
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
    // Get the custom theme extension
    final modeTheme = context.modeTheme;

    final balanceColor = account.currentBalance >= 0
        ? theme.colorScheme
            .primary // Or use specific income color from theme/palette
        : theme.colorScheme.error;

    // Use CardTheme from the base theme
    return Card(
      // Properties like elevation, margin, shape are now from theme.cardTheme
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: theme.listTileTheme.contentPadding ??
              const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 12.0), // Use theme padding
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: _buildIcon(context, modeTheme), // Use helper for icon
              ),
              SizedBox(
                  width: theme.listTileTheme.horizontalTitleGap ??
                      16.0), // Use theme spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name,
                        style:
                            theme.textTheme.titleMedium, // Use theme text style
                        overflow: TextOverflow.ellipsis),
                    Text(account.typeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme
                                .onSurfaceVariant) // Use theme text style
                        ),
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
