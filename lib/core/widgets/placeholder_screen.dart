import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // To allow popping
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class PlaceholderScreen extends StatelessWidget {
  final String featureName;
  const PlaceholderScreen({super.key, required this.featureName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BridgeScaffold(
      appBar: AppBar(
        title: Text(featureName),
        // Ensure a way back if pushed onto stack
        leading: context.canPop()
            ? IconButton(
                key: const ValueKey('button_placeholder_back'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const context.space.allXxxl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 80,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
              const SizedBox(height: 24),
              Text(
                featureName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Feature In Progress',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This section is currently under development and will be available soon. Stay tuned!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
