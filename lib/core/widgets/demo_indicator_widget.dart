import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

class DemoIndicatorWidget extends StatelessWidget {
  const DemoIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;

    // Use AnimatedOpacity for smooth appearance/disappearance
    return AnimatedOpacity(
      opacity: isInDemoMode ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: isInDemoMode
          ? Material(
              // Use Material for elevation and background
              elevation: 4.0, // Add slight elevation
              color: theme.colorScheme.secondaryContainer.withOpacity(0.95),
              child: Padding(
                padding: const BridgeEdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 18,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Demo Mode Active',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(), // Push button to the right
                    BridgeTextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                        padding: const BridgeEdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () async {
                        log.info("[DemoIndicator] Exit Demo button tapped.");
                        final confirmed = await AppDialogs.showConfirmation(
                          context,
                          title: 'Exit Demo Mode?',
                          content:
                              'This will clear demo data and restart setup. Continue?',
                          confirmText: 'Exit',
                        );
                        if (confirmed == true && context.mounted) {
                          context.read<SettingsBloc>().add(
                            const ExitDemoMode(),
                          );
                        }
                      },
                      key: const ValueKey('button_demoIndicator_exit'),
                      child: const Text('Exit Demo'),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(), // Return empty when not in demo mode
    );
  }
}
