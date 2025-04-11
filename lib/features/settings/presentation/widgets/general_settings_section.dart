// lib/features/settings/presentation/widgets/general_settings_section.dart
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/categories/presentation/pages/category_management_screen.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GeneralSettingsSection extends StatelessWidget {
  final SettingsState state;
  final bool isLoading;

  const GeneralSettingsSection({
    super.key,
    required this.state,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppCountry? currentCountry =
        AppCountries.findCountryByCode(state.selectedCountryCode);
    // --- Check Demo Mode ---
    final bool isEnabled = !isLoading && !state.isInDemoMode;
    // --- End Check ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'General'),
        SettingsListTile(
          enabled: isEnabled, // Use combined state
          leadingIcon: Icons.category_outlined,
          title: 'Manage Categories',
          subtitle: 'Add, edit, or delete custom categories',
          trailing: Icon(Icons.chevron_right,
              color: !isEnabled // Use combined state
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: !isEnabled // Use combined state
              ? null
              : () {
                  log.info("[SettingsPage] Navigating to Category Management.");
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CategoryManagementScreen(),
                  ));
                },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: currentCountry?.code,
            decoration: InputDecoration(
              labelText: 'Country / Currency',
              prefixIcon: Icon(Icons.public_outlined,
                  color: !isEnabled // Use combined state
                      ? theme.disabledColor
                      : theme.inputDecorationTheme.prefixIconColor),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              enabled: isEnabled, // Use combined state
            ),
            hint: const Text('Select Country'),
            isExpanded: true,
            items: AppCountries.availableCountries
                .map((AppCountry country) => DropdownMenuItem<String>(
                    value: country.code,
                    child: Text('${country.name} (${country.currencySymbol})')))
                .toList(),
            onChanged: !isEnabled // Use combined state
                ? null
                : (String? newValue) {
                    if (newValue != null) {
                      context.read<SettingsBloc>().add(UpdateCountry(newValue));
                    }
                  },
          ),
        ),
      ],
    );
  }
}
