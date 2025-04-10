// lib/features/reports/presentation/widgets/charts/spending_pie_chart.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';

class SpendingPieChart extends StatefulWidget {
  final List<CategorySpendingData> data;

  const SpendingPieChart({super.key, required this.data});

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int touchedIndex = -1;

  void _handleTap(BuildContext context, int index) {
    if (index < 0 || index >= widget.data.length) return;
    final tappedItem = widget.data[index];
    final filterBlocState = context.read<ReportFilterBloc>().state;

    // Construct filter map compatible with TransactionListPage
    final Map<String, String> filters = {
      // Keep existing date filters from the report filter bloc
      'startDate': filterBlocState.startDate.toIso8601String(),
      'endDate': filterBlocState.endDate.toIso8601String(),
      'type': TransactionType.expense.name, // Pie chart shows expenses
      'categoryId': tappedItem.categoryId, // Filter by tapped category
    };
    // Include account filters if they were applied in the report filter
    if (filterBlocState.selectedAccountIds.isNotEmpty) {
      filters['accountId'] = filterBlocState.selectedAccountIds.join(',');
    }

    log.info(
        "[SpendingPieChart] Navigating to transactions with filters: $filters");
    // Use push with 'extra' to pass filters cleanly
    context.push(RouteNames.transactionsList, extra: {'filters': filters});
  }

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
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
              // --- ADDED: Handle Tap for Drill-down ---
              if (event is FlTapUpEvent && touchedIndex != -1) {
                _handleTap(context, touchedIndex);
              }
              // --- END ADD ---
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
        value: item.totalAmount,
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
            : BorderSide(color: item.categoryColor.withOpacity(0)),
      );
    });
  }
}
