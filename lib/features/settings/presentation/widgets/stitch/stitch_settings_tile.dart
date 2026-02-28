import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';

class StitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const StitchSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppBridgeListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BridgeDecoration(
          color: kit.colors.primaryContainer,
          borderRadius: kit.radii.small,
        ),
        child: Icon(icon, color: kit.colors.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right, color: kit.colors.textSecondary),
      contentPadding: kit.spacing.allMd,
    );
  }
}
