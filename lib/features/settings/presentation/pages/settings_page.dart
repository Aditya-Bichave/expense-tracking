import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // If SettingsBloc is already provided globally in main.dart,
    // you don't need another BlocProvider here.
    // If it's NOT provided globally, keep this BlocProvider.
    // Assuming it IS provided globally based on main.dart update plan:
    return const SettingsView();

    /* If NOT provided globally, use this:
    return BlocProvider(
      // Ensure sl<SettingsBloc>() doesn't create a new one if singleton is needed
      // If SettingsBloc is Factory in DI, this is fine.
      // If SettingsBloc is LazySingleton, use context.read<SettingsBloc>() from parent
      // or ensure global provider exists. For simplicity here, assuming it's okay
      // to create via sl (depends on your DI registration type).
      // Best practice is usually a single global provider for such settings Blocs.
      create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: const SettingsView(),
    );
    */
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes for feedback (e.g., Snackbars on save)
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.status == SettingsStatus.error) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content:
                    Text('Error: ${state.errorMessage ?? 'Unknown error'}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
        // Optional: Show success Snackbars on successful saves if desired
        // else if (state.status == SettingsStatus.loaded && previousState.status == SettingsStatus.loading) {
        //    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text('Settings saved!')));
        // }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        // Use BlocBuilder to react to state changes from SettingsBloc for UI rebuilds
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            // Handle loading state for the initial load
            if (state.status == SettingsStatus.loading &&
                state.themeMode == SettingsState.defaultThemeMode) {
              // Show full page loader only on very first load maybe
              return const Center(child: CircularProgressIndicator());
            }
            // Show settings list even if there was a partial load error
            // Errors are handled by the BlocListener showing a SnackBar

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                // Settings tiles will be added here in Phase 3
                // --- Placeholder Examples (Update in Phase 3) ---
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Theme'),
                  subtitle: Text(state.themeMode
                      .toString()
                      .split('.')
                      .last
                      .capitalize()), // Display current theme
                  // Add onTap or trailing widget later for selection
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text(state.currencySymbol ??
                      'Not Set'), // Show current currency
                  // Add onTap or trailing widget later for selection
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Backup Data'),
                  onTap: () {/* Implement in Phase 4 */},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Data'),
                  onTap: () {/* Implement in Phase 4 */},
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_forever,
                      color: Theme.of(context).colorScheme.error),
                  title: Text('Clear All Data',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  onTap: () {/* Implement in Phase 4 */},
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.security),
                  title: const Text('App Lock'),
                  value: state.isAppLockEnabled, // Use state value
                  onChanged: (bool value) {
                    // Dispatch update event
                    context.read<SettingsBloc>().add(UpdateAppLock(value));
                    // Actual authentication logic will be added in Phase 5
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: const Text(
                      'Loading...'), // Placeholder - Implement in Phase 3
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Licenses'),
                  onTap: () {/* Implement in Phase 3 */},
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

// Simple extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
