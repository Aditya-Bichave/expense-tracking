import 'package:flutter/material.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/stitch/stitch_tab.dart';

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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
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
