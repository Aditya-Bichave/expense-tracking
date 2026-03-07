// lib/features/reports/presentation/widgets/charts/chart_utils.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';

class ChartUtils {
  // Common style for tooltip titles
  static TextStyle tooltipTitleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ) ??
        const BridgeTextStyle(fontWeight: FontWeight.bold);
  }

  // Common style for tooltip content (value)
  static TextStyle tooltipContentStyle(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: color ?? theme.colorScheme.primary,
        ) ??
        const BridgeTextStyle(fontWeight: FontWeight.w500);
  }

  // Common widget builder for left (Y-axis) titles
  static Widget leftTitleWidgets(
    BuildContext context,
    double value,
    TitleMeta meta,
    double maxY,
  ) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(fontSize: 10);

    if (value == 0) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text('0', style: style),
      );
    }
    if (value == meta.max || value <= 0) {
      return Container();
    }

    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      text = value.toStringAsFixed(0);
    }

    // Decide how many labels to show based on maxY
    final interval =
        meta.appliedInterval; // Use interval determined by fl_chart
    if (value % interval != 0 && value != meta.max) {
      // Only show labels at calculated intervals (and potentially 0)
      // return Container();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  // Common widget builder for bottom (X-axis) titles for category bar charts
  static Widget bottomTitleWidgets(
    BuildContext context,
    double value,
    TitleMeta meta,
    int dataLength,
    String Function(int) getTitle,
  ) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(fontSize: 10);
    final index = value.toInt();

    if (index < 0 || index >= dataLength) {
      return const SizedBox.shrink();
    }

    final title = getTitle(index);
    final displayText = title.length > 8
        ? '${title.substring(0, 6)}...'
        : title;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(displayText, style: style),
    );
  }

  // --- ADDED: Helper for simple sparkline data ---
  static LineChartData sparklineChartData(List<FlSpot> spots, Color color) {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(
        enabled: false,
      ), // Disable touch for sparklines
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color.withOpacity(0.8),
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false), // No area below sparkline
        ),
      ],
    );
  }

  // --- END ADDED ---
}
