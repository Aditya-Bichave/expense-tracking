// lib/features/settings/presentation/widgets/appearance_settings_section.dart
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppearanceSettingsSection extends StatelessWidget {
  final SettingsState state;
  final bool isLoading;

  const AppearanceSettingsSection({
    super.key,
    required this.state,
    required this.isLoading,
  });

  List<String> _getRelevantPaletteIdentifiers(UIMode uiMode) {
    switch (uiMode) {
      case UIMode.elemental:
        return [
          AppTheme.elementalPalette1,
          AppTheme.elementalPalette2,
          AppTheme.elementalPalette3,
          AppTheme.elementalPalette4
        ];
      case UIMode.quantum:
        return [
          AppTheme.quantumPalette1,
          AppTheme.quantumPalette2,
          AppTheme.quantumPalette3,
          AppTheme.quantumPalette4
        ];
      case UIMode.aether:
        return [
          AppTheme.aetherPalette1,
          AppTheme.aetherPalette2,
          AppTheme.aetherPalette3,
          AppTheme.aetherPalette4
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relevantPaletteIdentifiers =
        _getRelevantPaletteIdentifiers(state.uiMode);
    // --- Check Demo Mode ---
    final bool isEnabled = !isLoading && !state.isInDemoMode;
    // --- End Check ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Appearance'),
        SettingsListTile(
          // --- Use combined enabled state ---
          enabled: isEnabled,
          // --- End Use ---
          leadingIcon: Icons.view_quilt_outlined,
          title: 'UI Mode',
          subtitle: AppTheme.uiModeNames[state.uiMode] ??
              StringExtension(state.uiMode.name).capitalize(),
          trailing: PopupMenuButton<UIMode>(
            enabled: isEnabled, // Use combined state
            icon: const Icon(Icons.arrow_drop_down),
            tooltip: "Select UI Mode",
            initialValue: state.uiMode,
            onSelected: (UIMode newMode) =>
                context.read<SettingsBloc>().add(UpdateUIMode(newMode)),
            itemBuilder: (context) => UIMode.values
                .map((mode) => PopupMenuItem<UIMode>(
                      value: mode,
                      child: Text(
                          AppTheme.uiModeNames[mode] ??
                              StringExtension(mode.name).capitalize(),
                          style: theme.textTheme.bodyMedium),
                    ))
                .toList(),
          ),
        ),
        SettingsListTile(
          // --- Use combined enabled state ---
          enabled: isEnabled && relevantPaletteIdentifiers.isNotEmpty,
          // --- End Use ---
          leadingIcon: Icons.palette_outlined,
          title: 'Palette / Variant',
          subtitle: AppTheme.paletteNames[state.paletteIdentifier] ??
              state.paletteIdentifier,
          trailing: relevantPaletteIdentifiers.isEmpty
              ? null
              : PopupMenuButton<String>(
                  enabled: isEnabled, // Use combined state
                  icon: const Icon(Icons.arrow_drop_down),
                  tooltip: "Select Palette",
                  initialValue: state.paletteIdentifier,
                  onSelected: (String newIdentifier) => context
                      .read<SettingsBloc>()
                      .add(UpdatePaletteIdentifier(newIdentifier)),
                  itemBuilder: (context) => relevantPaletteIdentifiers
                      .map((id) => PopupMenuItem<String>(
                            value: id,
                            child: Text(AppTheme.paletteNames[id] ?? id,
                                style: theme.textTheme.bodyMedium),
                          ))
                      .toList(),
                ),
        ),
        SettingsListTile(
          // --- Use combined enabled state ---
          enabled: isEnabled,
          // --- End Use ---
          leadingIcon: Icons.brightness_6_outlined,
          title: 'Brightness Mode',
          subtitle: StringExtension(state.themeMode.name).capitalize(),
          trailing: PopupMenuButton<ThemeMode>(
            enabled: isEnabled, // Use combined state
            icon: const Icon(Icons.arrow_drop_down),
            tooltip: "Select Brightness Mode",
            initialValue: state.themeMode,
            onSelected: (ThemeMode newMode) =>
                context.read<SettingsBloc>().add(UpdateTheme(newMode)),
            itemBuilder: (context) => ThemeMode.values
                .map((mode) => PopupMenuItem<ThemeMode>(
                      value: mode,
                      child: Text(StringExtension(mode.name).capitalize(),
                          style: theme.textTheme.bodyMedium),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// Helper extension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
