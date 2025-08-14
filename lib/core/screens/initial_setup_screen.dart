// lib/screens/initial_setup_screen.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Removed Router import

class InitialSetupScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  @override
  void initState() {
    super.initState();
    // Reset the skip flag if user lands on this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsBloc>().add(const ResetSkipSetupFlag());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsBloc = context.watch<SettingsBloc>();
    final currentCountryCode = settingsBloc.state.selectedCountryCode;
    final currentCountry = AppCountries.findCountryByCode(currentCountryCode);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Branding/Welcome ---
              Icon(
                Icons.savings_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to Spend Savvy!',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Track your expenses, manage budgets, and achieve your financial goals.',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // --- Currency Selection ---
              ElevatedButton.icon(
                icon: const Icon(Icons.language),
                label: Text(
                  currentCountry != null
                      ? 'Currency: ${currentCountry.name} (${currentCountry.currencySymbol})'
                      : 'Select Currency',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: () => _showCurrencyPicker(context),
              ),
              const SizedBox(height: 24),

              // --- Demo Mode Button ---
              OutlinedButton.icon(
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explore Demo Mode'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.colorScheme.primary),
                  foregroundColor: theme.colorScheme.primary,
                ),
                onPressed: () {
                  log.info("[InitialSetup] Demo Mode button tapped.");
                  context.read<SettingsBloc>().add(const EnterDemoMode());
                  // Router redirect will handle navigation now
                  context.go(RouteNames.dashboard);
                },
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("OR")),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // --- Authentication Buttons ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
                onPressed: () {
                  log.warning("[InitialSetup] Sign Up navigation TBD");
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Sign Up: Coming Soon!")));
                },
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  log.warning("[InitialSetup] Log In navigation TBD");
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Log In: Coming Soon!")));
                },
                child: const Text('Log In'),
              ),
              const SizedBox(height: 24),

              // --- Skip Button ---
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  log.info("[InitialSetup] Skip button tapped.");
                  // --- MODIFIED: Dispatch SkipSetup event FIRST ---
                  context.read<SettingsBloc>().add(const SkipSetup());
                  // --- END MODIFICATION ---
                  context.go(RouteNames.dashboard);
                },
                child: const Text('Skip for Now'),
              ),
              // --- End Skip Button ---
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (builderContext) {
        return BlocProvider.value(
          value: BlocProvider.of<SettingsBloc>(context),
          child: const CurrencyPickerSheet(),
        );
      },
    );
  }
}

// --- Currency Picker Sheet Widget (No changes needed here) ---
class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsBloc = context.watch<SettingsBloc>();
    final currentCode = settingsBloc.state.selectedCountryCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Wrap(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Select Your Currency',
                  style: theme.textTheme.titleLarge),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppCountries.availableCountries.length,
                itemBuilder: (context, index) {
                  final country = AppCountries.availableCountries[index];
                  final bool isSelected = country.code == currentCode;
                  return RadioListTile<String>(
                    title: Text('${country.name} (${country.currencySymbol})'),
                    value: country.code,
                    groupValue: currentCode,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (String? value) {
                      if (value != null) {
                        context.read<SettingsBloc>().add(UpdateCountry(value));
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
