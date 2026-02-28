import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

class StitchAuthButtons extends StatelessWidget {
  final VoidCallback onPhoneTap;
  final VoidCallback onEmailTap;

  const StitchAuthButtons({
    super.key,
    required this.onPhoneTap,
    required this.onEmailTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onPhoneTap,
            icon: Icon(Icons.smartphone, color: theme.colorScheme.onPrimary),
            label: Text(
              'Continue with Phone',
              style: BridgeTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BridgeBorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onEmailTap,
            icon: Icon(
              Icons.email_outlined,
              color: theme.colorScheme.onSurface,
            ),
            label: Text(
              'Continue with Email',
              style: BridgeTextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withOpacity(0.5),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BridgeBorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
