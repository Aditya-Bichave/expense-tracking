import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // For random colors

class AssetDistributionPieChart extends StatefulWidget {
  final Map<String, double> accountBalances; // Map<AccountName, Balance>

  const AssetDistributionPieChart({super.key, required this.accountBalances});

  @override
  State<StatefulWidget> createState() => AssetDistributionPieChartState();
}

class AssetDistributionPieChartState extends State<AssetDistributionPieChart> {
  int touchedIndex = -1;
  final Random _random = Random();

  // Generate pseudo-random colors for chart sections
  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(200) + 55, // Avoid very dark colors
      _random.nextInt(200) + 55,
      _random.nextInt(200) + 55,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final positiveBalances = Map.fromEntries(
        widget.accountBalances.entries.where((entry) => entry.value > 0));

    if (positiveBalances.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No positive asset balances to display.')),
        ),
      );
    }

    // Generate colors once per build for consistency during rebuilds unless data changes
    final List<Color> sectionColors =
        List.generate(positiveBalances.length, (_) => _getRandomColor());
    final List<String> accountNames = positiveBalances.keys.toList();
    final List<double> balances = positiveBalances.values.toList();
    final double totalPositiveBalance =
        balances.fold(0, (sum, item) => sum + item);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Distribution',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
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
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2, // Space between sections
                  centerSpaceRadius: 40, // Radius of the center hole
                  sections: showingSections(
                      positiveBalances, sectionColors, totalPositiveBalance),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Add Legends
            Wrap(
              // Use Wrap for legends if many accounts
              spacing: 8.0,
              runSpacing: 4.0,
              children: List.generate(accountNames.length, (index) {
                return _buildLegend(accountNames[index], sectionColors[index]);
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String name, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  List<PieChartSectionData> showingSections(
      Map<String, double> data, List<Color> colors, double totalValue) {
    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final balance = data.values.elementAt(i);
      final percentage = totalValue > 0 ? (balance / totalValue * 100) : 0.0;

      return PieChartSectionData(
        color: colors[i],
        value: balance, // The actual value determines the size
        title: '${percentage.toStringAsFixed(1)}%', // Display percentage
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Or adaptive color based on background
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
        // Optional: Tooltip on touch
        // badgeWidget: isTouched ? Text(accountName) : null,
        // badgePositionPercentageOffset: .98,
      );
    });
  }
}
