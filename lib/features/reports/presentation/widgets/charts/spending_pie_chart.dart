// lib/features/reports/presentation/widgets/charts/spending_pie_chart.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';

class SpendingPieChart extends StatefulWidget {
  final List<CategorySpendingData> data;
  final Function(int index)? onTapSlice; // Callback for tap

  const SpendingPieChart({
    super.key,
    required this.data,
    this.onTapSlice,
  });

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              int previousTouchedIndex = touchedIndex; // Store previous index
              touchedIndex = -1; // Reset first

              if (event.isInterestedForInteractions &&
                  pieTouchResponse != null &&
                  pieTouchResponse.touchedSection != null) {
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
                // Trigger callback on tap up
                if (event is FlTapUpEvent &&
                    touchedIndex != -1 &&
                    previousTouchedIndex == touchedIndex) {
                  widget.onTapSlice?.call(touchedIndex);
                }
              }
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: showingSections(),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    final theme = Theme.of(context);
    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      final item = widget.data[i];
      final percentage = item.percentage * 100;
      final titleColor = item.categoryColor.computeLuminance() > 0.5
          ? Colors.black87
          : Colors.white;

      return PieChartSectionData(
        color: item.categoryColor,
        // --- FIXED: Use currentTotalAmount ---
        value: item.currentTotalAmount,
        // --- END FIX ---
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: titleColor,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        borderSide: isTouched
            ? BorderSide(color: theme.colorScheme.surface, width: 2)
            : BorderSide(color: item.categoryColor.withAlpha((255 * 0).round())),
      );
    });
  }
}
