import 'package:flutter/material.dart';

class StitchAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String currencySymbol;

  const StitchAmountInput({
    super.key,
    required this.controller,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Currency Selector Mock
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'USD (\$)',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Amount Input
        Stack(
          alignment: Alignment.center,
          children: [
            // Currency Symbol Prefix
            Transform.translate(
              offset: const Offset(-60, 0),
              child: Text(
                currencySymbol,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Container(
          height: 4,
          width: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
