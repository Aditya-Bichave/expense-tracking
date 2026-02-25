import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  @override
  void initState() {
    super.initState();
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
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                icon: const Icon(Icons.language),
                label: Text(
                  currentCountry != null
                      ? 'Currency: ${currentCountry.name} (${currentCountry.currencySymbol})'
                      : 'Select Currency',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: () => _showCurrencyPicker(context),
              ),
              const SizedBox(height: 24),
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
                  context.go(RouteNames.dashboard);
                },
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                ),
                onPressed: () {
                  context.go(RouteNames.login);
                },
                child: const Text('Sign Up / Log In'),
              ),
              const SizedBox(height: 24),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  log.info("[InitialSetup] Skip button tapped.");
                  context.read<SettingsBloc>().add(const SkipSetup());
                  context.go(RouteNames.dashboard);
                },
                child: const Text('Skip for Now'),
              ),
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
              child: Text(
                'Select Your Currency',
                style: theme.textTheme.titleLarge,
              ),
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
