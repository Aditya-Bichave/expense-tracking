import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming SettingsBloc is provided globally via main.dart
    return const SettingsView();
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  // --- Predefined Currency List ---
  static const List<String> _currencySymbols = [
    'USD', 'EUR', 'GBP', 'JPY', 'INR', 'CAD', 'AUD', 'CHF' // Add more as needed
  ];

  // Helper to build Theme Popup Menu Items
  List<PopupMenuEntry<ThemeMode>> _buildThemeMenuItems(BuildContext context) {
    return [
      PopupMenuItem<ThemeMode>(
        value: ThemeMode.light,
        child: Text('Light', style: Theme.of(context).textTheme.bodyMedium),
      ),
      PopupMenuItem<ThemeMode>(
        value: ThemeMode.dark,
        child: Text('Dark', style: Theme.of(context).textTheme.bodyMedium),
      ),
      PopupMenuItem<ThemeMode>(
        value: ThemeMode.system,
        child: Text('System Default',
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // Consolidated error handling for main settings errors
        if (state.status == SettingsStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Error: ${state.errorMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
        // Handle package info errors separately if needed
        else if (state.packageInfoStatus == PackageInfoStatus.error &&
            state.packageInfoError != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Version Error: ${state.packageInfoError}'),
                backgroundColor: Colors.orange, // Use different color?
              ),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            // Show full loading indicator only if both main settings and package info are initial/loading
            if ((state.status == SettingsStatus.loading ||
                    state.status == SettingsStatus.initial) &&
                (state.packageInfoStatus == PackageInfoStatus.loading ||
                    state.packageInfoStatus == PackageInfoStatus.initial)) {
              return const Center(child: CircularProgressIndicator());
            }

            // Build the settings list
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                // --- Theme Setting ---
                ListTile(
                  leading: const Icon(Icons.color_lens_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(state.themeMode.name.capitalize()),
                  trailing: PopupMenuButton<ThemeMode>(
                    icon: const Icon(Icons.arrow_drop_down),
                    tooltip: "Select Theme",
                    onSelected: (ThemeMode newMode) {
                      context.read<SettingsBloc>().add(UpdateTheme(newMode));
                    },
                    itemBuilder: _buildThemeMenuItems,
                  ),
                ),
                const Divider(),

                // --- Currency Setting ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _currencySymbols.contains(state.currencySymbol)
                        ? state.currencySymbol
                        : null, // Handle if saved symbol isn't in list
                    decoration: const InputDecoration(
                      labelText: 'Currency Symbol',
                      icon: Icon(Icons.attach_money_outlined),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    hint: const Text('Select Currency'),
                    isExpanded: true,
                    items: _currencySymbols.map((String symbol) {
                      return DropdownMenuItem<String>(
                        value: symbol,
                        child: Text(symbol),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateCurrency(newValue));
                      }
                    },
                    validator: (value) =>
                        value == null ? 'Please select a currency' : null,
                  ),
                ),
                const Divider(),

                // --- Data Management Placeholders ---
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Backup Data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    /* Implement in Phase 4 */
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                          content: Text('Backup not yet implemented')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restore Data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    /* Implement in Phase 4 */
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                          content: Text('Restore not yet implemented')));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Clear All Data',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    /* Implement in Phase 4 */
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                          content: Text('Clear Data not yet implemented')));
                  },
                ),
                const Divider(),

                // --- App Lock Setting ---
                SwitchListTile(
                  secondary: const Icon(Icons.security_outlined),
                  title: const Text('App Lock'),
                  value: state.isAppLockEnabled,
                  onChanged: (bool value) {
                    context.read<SettingsBloc>().add(UpdateAppLock(value));
                    // Actual authentication logic in Phase 5
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                          content: Text(
                              'App Lock requires restart (Not fully implemented yet)')));
                  },
                ),
                const Divider(),

                // --- App Version ---
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle:
                      Text(state.packageInfoStatus == PackageInfoStatus.loading
                          ? 'Loading...'
                          : state.packageInfoStatus == PackageInfoStatus.error
                              ? 'Error loading version'
                              : state.appVersion ?? 'N/A'),
                  // No action needed
                ),

                // --- Licenses ---
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => const LicensePage(
                            // Optional: Customize application name/version/icon
                            // applicationName: 'Expense Tracker',
                            // applicationVersion: state.appVersion ?? 'N/A',
                            // applicationIcon: Icon(Icons.wallet_outlined), // Your app icon
                            // applicationLegalese: '© 2024 Your Name/Company',
                            ),
                      ),
                    );
                  },
                ),
                const Divider(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Simple extension to capitalize first letter (keep this)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
