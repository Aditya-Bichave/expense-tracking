import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class SpendingPieChart extends StatefulWidget {
  final List<CategorySpendingData> data;
  final Function(int index)? onTapSlice; // Callback for tap

  const SpendingPieChart({super.key, required this.data, this.onTapSlice});

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    if (widget.data.isEmpty) {
      return Center(
        child: Text("No data to display", style: kit.typography.body),
      );
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              int previousTouchedIndex = touchedIndex; // Store previous index

              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }

              final newIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;

              if (newIndex != -1) {
                touchedIndex = newIndex;
                // Trigger callback on tap up
                if (event is FlTapUpEvent &&
                    previousTouchedIndex == touchedIndex) {
                  widget.onTapSlice?.call(touchedIndex);
                }
              } else {
                touchedIndex = -1;
              }
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: showingSections(context),
      ),
    );
  }

  List<PieChartSectionData> showingSections(BuildContext context) {
    final kit = context.kit;
    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      final item = widget.data[i];
      final percentage = item.percentage * 100;

      // Determine text color based on slice brightness
      final titleColor = item.categoryColor.computeLuminance() > 0.5
          ? kit.colors.textPrimary
          : kit.colors.onPrimary;

      return PieChartSectionData(
        color: item.categoryColor,
        value: item.currentTotalAmount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: titleColor,
          shadows: [Shadow(color: kit.colors.shadow, blurRadius: 2)],
        ),
        borderSide: isTouched
            ? BorderSide(color: kit.colors.surface, width: 2)
            : BorderSide(color: item.categoryColor.withOpacity(0)),
      );
    });
  }
}
