import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';

class AppGroupCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final Widget? action;

  const AppGroupCard({
    super.key,
    this.title,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: kit.spacing.hMd.copyWith(bottom: kit.spacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: kit.typography.labelLarge.copyWith(
                    color: kit.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        ],
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: kit.colors.borderSubtle,
                    indent: kit.spacing.md,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
