import 'package:flutter/material.dart';

// A standardized ListTile for settings for consistent styling and icon handling
class SettingsListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingsListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.leadingIcon,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  // Helper copied from SettingsPage to keep icon logic consistent
  Widget _buildLeadingIcon(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.listTileTheme.iconColor ?? theme.colorScheme.onSurfaceVariant
        : theme.disabledColor;
    return Icon(leadingIcon, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.listTileTheme.titleTextStyle ?? theme.textTheme.titleMedium;
    final subtitleStyle =
        theme.listTileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium;
    final disabledColor = theme.disabledColor;

    return ListTile(
      enabled: enabled,
      leading: _buildLeadingIcon(context),
      title: Text(
        title,
        style: enabled
            ? titleStyle
            : titleStyle?.copyWith(color: disabledColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: enabled
                  ? subtitleStyle
                  : subtitleStyle?.copyWith(color: disabledColor),
            )
          : null,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      visualDensity: VisualDensity.comfortable, // Adjust density maybe
      contentPadding: theme.listTileTheme.contentPadding, // Use themed padding
    );
  }
}
