import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:expense_tracker/main.dart'; // Import logger

class AssetDistributionPieChart extends StatefulWidget {
  final Map<String, double> accountBalances; // Map<AccountName, Balance>

  const AssetDistributionPieChart({super.key, required this.accountBalances});

  @override
  State<StatefulWidget> createState() => AssetDistributionPieChartState();
}

class AssetDistributionPieChartState extends State<AssetDistributionPieChart> {
  int touchedIndex = -1;
  // Use a fixed seed for pseudo-randomness, or generate based on account names for consistency
  late Random _random;
  late Map<String, Color> _colorCache; // Cache colors per account name

  @override
  void initState() {
    super.initState();
    // Initialize random with a seed based on the initial data keys hash code for some consistency
    // This isn't perfect but better than fully random on every build.
    _random = Random(widget.accountBalances.keys.hashCode);
    _colorCache = {};
    _generateColorCache(widget.accountBalances.keys);
    log.info(
        "[PieChart] Initialized with ${widget.accountBalances.length} accounts.");
  }

  @override
  void didUpdateWidget(covariant AssetDistributionPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If account keys change significantly, regenerate colors
    if (widget.accountBalances.keys.toSet() !=
        oldWidget.accountBalances.keys.toSet()) {
      log.info("[PieChart] Account keys changed, regenerating color cache.");
      _random = Random(widget
          .accountBalances.keys.hashCode); // Reset random based on new keys
      _generateColorCache(widget.accountBalances.keys);
      // Reset touched index if the data changes significantly
      touchedIndex = -1;
    }
  }

  void _generateColorCache(Iterable<String> accountNames) {
    _colorCache.clear();
    for (final name in accountNames) {
      _colorCache[name] = _generateColorForName(name);
    }
  }

  // Generate a color based on the account name hash for better stability
  Color _generateColorForName(String name) {
    // Simple hash-based color generation
    final hash = name.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    // Ensure reasonable brightness/saturation
    return Color.fromRGBO((r % 156) + 100, (g % 156) + 100, (b % 156) + 100, 1);

    // --- Alternative: Keep using random but cache it ---
    // if (!_colorCache.containsKey(name)) {
    //   _colorCache[name] = Color.fromRGBO(
    //     _random.nextInt(180) + 75, // Slightly less random range
    //     _random.nextInt(180) + 75,
    //     _random.nextInt(180) + 75,
    //     1,
    //   );
    // }
    // return _colorCache[name]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    log.info("[PieChart] Build method. TouchedIndex: $touchedIndex");

    // Filter out accounts with zero or negative balance for the chart itself
    final positiveBalances = Map.fromEntries(
        widget.accountBalances.entries.where((entry) => entry.value > 0));

    log.info(
        "[PieChart] Filtered positive balances: ${positiveBalances.length} accounts.");

    if (positiveBalances.isEmpty) {
      log.info("[PieChart] No positive balances to display.");
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
              child: Text('No positive asset balances to chart.',
                  style: theme.textTheme.bodyMedium)),
        ),
      );
    }

    // Prepare data for the chart
    final List<String> accountNames = positiveBalances.keys.toList();
    final List<double> balances = positiveBalances.values.toList();
    final double totalPositiveBalance =
        balances.fold(0.0, (sum, item) => sum + item);

    // Get colors from cache/generation
    final List<Color> sectionColors = accountNames
        .map((name) => _colorCache[name] ?? _generateColorForName(name))
        .toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asset Distribution',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.4, // Adjust aspect ratio as needed
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          if (touchedIndex != -1) {
                            log.info("[PieChart] Touch ended or invalid.");
                            touchedIndex = -1; // Reset on touch end/invalid
                          }
                          return;
                        }
                        log.info(
                            "[PieChart] Touched section index: ${pieTouchResponse.touchedSection!.touchedSectionIndex}");
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50, // Make center hole larger
                  sections: showingSections(positiveBalances, sectionColors,
                      totalPositiveBalance, theme),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Legends
            Wrap(
              spacing: 12.0, // Increase spacing
              runSpacing: 8.0,
              alignment: WrapAlignment.center, // Center legends
              children: List.generate(accountNames.length, (index) {
                return _buildLegend(
                    accountNames[index], sectionColors[index], theme);
              }),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String name, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)), // Use circle
        const SizedBox(width: 6),
        Text(name, style: theme.textTheme.bodySmall),
      ],
    );
  }

  List<PieChartSectionData> showingSections(Map<String, double> data,
      List<Color> colors, double totalValue, ThemeData theme) {
    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 15.0 : 11.0; // Adjust font sizes
      final radius = isTouched ? 70.0 : 60.0; // Increase radius difference
      final balance = data.values.elementAt(i);
      final percentage = totalValue > 0 ? (balance / totalValue * 100) : 0.0;

      // Determine title color based on background luminance
      final titleColor =
          colors[i].computeLuminance() > 0.5 ? Colors.black : Colors.white;

      return PieChartSectionData(
        color: colors[i],
        value: balance,
        title:
            '${percentage.toStringAsFixed(0)}%', // Show percentage, no decimal if small
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: titleColor,
          shadows: const [
            Shadow(color: Colors.black26, blurRadius: 2)
          ], // Softer shadow
        ),
        borderSide: isTouched // Add border when touched
            ? BorderSide(color: theme.colorScheme.surface, width: 2)
            : BorderSide(
                color: colors[i].withOpacity(0)), // Use theme surface color
      );
    });
  }
}
