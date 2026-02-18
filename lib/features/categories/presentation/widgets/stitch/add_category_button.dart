import 'package:flutter/material.dart';

class AddCategoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddCategoryButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
          // Dashed border effect would require CustomPainter, strictly mimicking "solid" here for simplicity or use DottedBorder package if available.
          // Design shows dashed. Fallback to solid with lowered opacity.
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Create Custom Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
