import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

class PersonalConstellationWidget extends StatelessWidget {
  final FinancialOverview overview;

  const PersonalConstellationWidget({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;

    // TODO: Implement the actual constellation visualization
    // Likely involves CustomPaint, animations, particle effects.

    // Placeholder Implementation:
    return Container(
      decoration: BoxDecoration(
        // Example gradient background
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.8),
            theme.colorScheme.surface, // Use surface for lower part
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border_outlined,
                  size: 80, color: theme.colorScheme.tertiary), // Star icon
              const SizedBox(height: 20),
              Text(
                'Your Financial Constellation',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Mapping your financial journey...',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildConstellationStat(
                  context,
                  Icons.brightness_7,
                  "Overall Balance",
                  overview.overallBalance,
                  theme.colorScheme.primary),
              _buildConstellationStat(
                  context,
                  Icons.moving_outlined,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConstellationStat(BuildContext context, IconData icon,
      String label, double value, Color valueColor) {
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
