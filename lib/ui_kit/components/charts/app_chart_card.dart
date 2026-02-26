import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';

class AppChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final Widget? action;
  final String? subtitle;
  final bool isEmpty;
  final Widget? emptyState;

  const AppChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.action,
    this.subtitle,
    this.isEmpty = false,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: kit.typography.title,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: kit.typography.caption.copyWith(color: kit.colors.textSecondary),
                    ),
                ],
              ),
              if (action != null) action!,
            ],
          ),
          kit.spacing.gapLg,
          if (isEmpty)
            AspectRatio(
              aspectRatio: 1.5,
              child: emptyState ??
                  Center(
                    child: Text(
                      'No data available',
                      style: kit.typography.body.copyWith(color: kit.colors.textMuted),
                    ),
                  ),
            )
          else
            chart,
        ],
      ),
    );
  }
}
