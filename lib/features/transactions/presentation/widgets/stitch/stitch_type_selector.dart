import 'package:flutter/material.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/stitch/stitch_tab.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class StitchTypeSelector extends StatefulWidget {
  final ValueChanged<StitchTab> onTypeChanged;

  const StitchTypeSelector({super.key, required this.onTypeChanged});

  @override
  State<StitchTypeSelector> createState() => _StitchTypeSelectorState();
}

class _StitchTypeSelectorState extends State<StitchTypeSelector> {
  StitchTab _selectedTab = StitchTab.personal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: context.space.allXs,
      decoration: BridgeDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: context.kit.radii.large,
      ),
      child: Row(
        children: StitchTab.values.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = tab);
                widget.onTypeChanged(tab);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: context.space.vMd,
                decoration: BridgeDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: context.kit.radii.medium,
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
