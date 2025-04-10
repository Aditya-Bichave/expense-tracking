import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG
// Import asset catalog
import 'package:expense_tracker/core/widgets/app_card.dart'; // Import AppCard

class AccountCard extends StatelessWidget {
  final AssetAccount account;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  // _buildIcon helper remains the same as previous refactor...
  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    IconData defaultIconData = account.iconData; // Get fallback from entity
    String? svgPath;
    String accountTypeKey =
        account.type.name.toLowerCase(); // Use enum name as key

    if (modeTheme != null) {
      // Try to get SVG path from theme extension based on account type name
      svgPath = modeTheme.assets.getCategoryIcon(
          // Using category map for account types too
          accountTypeKey,
          defaultPath:
              '' // No default SVG path needed here, will fallback to IconData
          );
      if (svgPath.isEmpty) svgPath = null;
    }

    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
            theme.colorScheme.onSecondaryContainer, // Use themed color
            BlendMode.srcIn),
      );
    } else {
      // Fallback to Material Icon defined in AssetAccount entity
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

    // Determine balance color based on sign and theme
    final balanceColor = account.currentBalance >= 0
        ? (modeTheme?.incomeGlowColor ?? theme.colorScheme.primary)
        : (modeTheme?.expenseGlowColor ?? theme.colorScheme.error);

    // Use AppCard as the base
    return AppCard(
      onTap: onTap,
      // Let AppCard handle margin, padding etc. based on theme
      child: Row(
        // Define the specific content for AccountCard
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: _buildIcon(context, modeTheme),
          ),
          SizedBox(
              width: modeTheme?.listItemPadding.left ?? 16), // Themed spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis),
                Text(account.typeName, // Display type name from entity
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
              width: modeTheme?.listItemPadding.right ?? 16), // Themed spacing
          // Animate balance color change
          AnimatedDefaultTextStyle(
            duration:
                modeTheme?.fastDuration ?? const Duration(milliseconds: 150),
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: balanceColor,
            ),
            child: Text(CurrencyFormatter.format(
                account.currentBalance, currencySymbol)),
          ),
        ],
      ),
    );
  }
}
