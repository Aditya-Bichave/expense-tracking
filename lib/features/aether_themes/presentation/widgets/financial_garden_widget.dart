import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // If needed to read settings directly
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

class FinancialGardenWidget extends StatelessWidget {
  final FinancialOverview overview;

  const FinancialGardenWidget({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState =
        context.watch<SettingsBloc>().state; // Example: Read settings if needed

    // TODO: Implement the actual garden visualization
    // This requires significant custom painting or potentially using
    // animation libraries like Rive or game engines adapted for Flutter.

    // Placeholder Implementation:
    return Container(
      decoration: BoxDecoration(
        // Example gradient background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_florist_outlined,
                  size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'Your Financial Garden',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Visualize your finances growing!',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Display some basic data thematically
              _buildGardenStat(context, Icons.spa_outlined, "Overall Balance",
                  overview.overallBalance, theme.colorScheme.primary),
              _buildGardenStat(
                  context,
                  Icons.grass_outlined,
                  "Net Flow",
                  overview.netFlow,
                  overview.netFlow >= 0
                      ? Colors.green.shade700
                      : theme.colorScheme.error),
              const SizedBox(height: 20),
              Text(
                "(Full visualization coming soon!)",
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
              // Add more complex visualizations later
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGardenStat(BuildContext context, IconData icon, String label,
      double value, Color valueColor) {
    final currencySymbol = context.read<SettingsBloc>().state.currencySymbol;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 10),
          Text('$label: ', style: theme.textTheme.titleMedium),
          Text(
            CurrencyFormatter.format(value, currencySymbol),
            style: theme.textTheme.titleMedium
                ?.copyWith(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
