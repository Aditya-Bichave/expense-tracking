// lib/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:flutter_bloc/flutter_bloc.dart'; // To read settings
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';

class AssetDistributionPieChart extends StatefulWidget {
  final Map<String, double> accountBalances; // Map<AccountName, Balance>

  const AssetDistributionPieChart({super.key, required this.accountBalances});

  @override
  State<StatefulWidget> createState() => AssetDistributionPieChartState();
}

class AssetDistributionPieChartState extends State<AssetDistributionPieChart> {
  int touchedIndex = -1;
  late Map<String, Color> _colorCache;

  static const List<Color> colorPalette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.amber,
    Colors.teal,
    Colors.pink,
    Colors.lime,
  ];

  @visibleForTesting
  static Map<String, Color> generateColorMap(Iterable<String> accountNames) {
    final map = <String, Color>{};
    int index = 0;
    for (final name in accountNames) {
      map[name] = colorPalette[index % colorPalette.length];
      index++;
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _colorCache = {};
    _generateColorCache(widget.accountBalances.keys);
    log.info(
      "[PieChart] Initialized with ${widget.accountBalances.length} accounts.",
    );
  }

  @override
  void didUpdateWidget(covariant AssetDistributionPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accountBalances.keys.toSet() !=
        oldWidget.accountBalances.keys.toSet()) {
      log.info("[PieChart] Account keys changed, regenerating color cache.");
      _generateColorCache(widget.accountBalances.keys);
      touchedIndex = -1;
    }
  }

  void _generateColorCache(Iterable<String> accountNames) {
    _colorCache = generateColorMap(accountNames);
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;

    log.info(
      "[PieChart] Build method. TouchedIndex: $touchedIndex, Mode: $uiMode",
    );

    // --- Quantum Mode: Return null, handled by DashboardPage ---
    // Note: We could render a table here, but dashboard page already does
    if (uiMode == UIMode.quantum) {
      log.info("[PieChart] Quantum mode active. Returning SizedBox.shrink().");
      return const SizedBox.shrink(); // Dashboard page handles Quantum display
    }
    // --- End Quantum Mode Handling ---

    // Filter out accounts with zero or negative balance for the chart itself
    final positiveBalances = Map.fromEntries(
      widget.accountBalances.entries.where((entry) => entry.value > 0),
    );

    log.info(
      "[PieChart] Filtered positive balances: ${positiveBalances.length} accounts.",
    );

    if (positiveBalances.isEmpty) {
      log.info("[PieChart] No positive balances to display.");
      return AppCard(
        padding: kit.spacing.allXl,
        child: Center(
          child: BridgeText(
            'No positive asset balances to chart.',
            style: kit.typography.body,
          ),
        ),
      );
    }

    // Prepare data for the chart
    final List<String> accountNames = positiveBalances.keys.toList();
    final List<double> balances = positiveBalances.values.toList();
    final double totalPositiveBalance = balances.fold(
      0.0,
      (sum, item) => sum + item,
    );

    // Get colors from cache
    final List<Color> sectionColors = accountNames
        .map((name) => _colorCache[name]!)
        .toList();

    return AppCard(
      padding: kit.spacing.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BridgeText(
            'Asset Distribution',
            style: kit.typography.headline.copyWith(
              color: kit.colors.textSecondary,
            ),
          ),
          kit.spacing.gapLg,
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
                        "[PieChart] Touched section index: ${pieTouchResponse.touchedSection!.touchedSectionIndex}",
                      );
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 50, // Make center hole larger
                sections: showingSections(
                  positiveBalances,
                  sectionColors,
                  totalPositiveBalance,
                  kit,
                ),
              ),
            ),
          ),
          kit.spacing.gapLg,
          // Legends
          Wrap(
            spacing: kit.spacing.md,
            runSpacing: kit.spacing.sm,
            alignment: WrapAlignment.center,
            children: List.generate(accountNames.length, (index) {
              return _buildLegend(
                accountNames[index],
                sectionColors[index],
                kit,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String name, Color color, AppKitTheme kit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BridgeDecoration(color: color, shape: BoxShape.circle),
        ),
        kit.spacing.gapXs,
        BridgeText(name, style: kit.typography.caption),
      ],
    );
  }

  List<PieChartSectionData> showingSections(
    Map<String, double> data,
    List<Color> colors,
    double totalValue,
    AppKitTheme kit,
  ) {
    // Reduce/remove animations in Quantum mode (handled by main check now)
    // bool isQuantum = context.read<SettingsBloc>().state.uiMode == UIMode.quantum;

    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 15.0 : 11.0;
      final radius = isTouched ? 70.0 : 60.0;
      final balance = data.values.elementAt(i);
      final percentage = totalValue > 0 ? (balance / totalValue * 100) : 0.0;
      final titleColor = colors[i].computeLuminance() > 0.5
          ? Colors.black
          : Colors.white;

      return PieChartSectionData(
        color: colors[i],
        value: balance,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: BridgeTextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: titleColor,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        borderSide: isTouched
            ? BorderSide(color: kit.colors.surface, width: 2)
            : BorderSide(color: colors[i].withOpacity(0)),
      );
    });
  }
}
