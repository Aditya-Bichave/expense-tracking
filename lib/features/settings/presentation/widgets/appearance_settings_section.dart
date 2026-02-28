import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';

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
          AppTheme.elementalPalette4,
        ];
      case UIMode.quantum:
        return [
          AppTheme.quantumPalette1,
          AppTheme.quantumPalette2,
          AppTheme.quantumPalette3,
          AppTheme.quantumPalette4,
        ];
      case UIMode.aether:
        return [
          AppTheme.aetherPalette1,
          AppTheme.aetherPalette2,
          AppTheme.aetherPalette3,
          AppTheme.aetherPalette4,
        ];
      case UIMode.stitch:
        return [AppTheme.stitchPalette1];
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final relevantPaletteIdentifiers = _getRelevantPaletteIdentifiers(
      state.uiMode,
    );
    final bool isEnabled = !isLoading && !state.isInDemoMode;

    return AppSection(
      title: 'Appearance',
      child: Column(
        children: [
          AppBridgeListTile(
            leading: Icon(
              Icons.view_quilt_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('UI Mode'),
            subtitle: Text(
              AppTheme.uiModeNames[state.uiMode] ??
                  (toBeginningOfSentenceCase(state.uiMode.name) ??
                      state.uiMode.name),
            ),
            trailing: PopupMenuButton<UIMode>(
              enabled: isEnabled,
              icon: Icon(
                Icons.arrow_drop_down,
                color: kit.colors.textSecondary,
              ),
              tooltip: "Select UI Mode",
              initialValue: state.uiMode,
              onSelected: (UIMode newMode) =>
                  context.read<SettingsBloc>().add(UpdateUIMode(newMode)),
              itemBuilder: (context) => UIMode.values
                  .map(
                    (mode) => PopupMenuItem<UIMode>(
                      value: mode,
                      child: Text(
                        AppTheme.uiModeNames[mode] ??
                            (toBeginningOfSentenceCase(mode.name) ?? mode.name),
                        style: kit.typography.body,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          AppBridgeListTile(
            leading: Icon(
              Icons.palette_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Palette / Variant'),
            subtitle: Text(
              AppTheme.paletteNames[state.paletteIdentifier] ??
                  state.paletteIdentifier,
            ),
            trailing: relevantPaletteIdentifiers.isEmpty
                ? null
                : PopupMenuButton<String>(
                    enabled: isEnabled,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: kit.colors.textSecondary,
                    ),
                    tooltip: "Select Palette",
                    initialValue: state.paletteIdentifier,
                    onSelected: (String newIdentifier) => context
                        .read<SettingsBloc>()
                        .add(UpdatePaletteIdentifier(newIdentifier)),
                    itemBuilder: (context) => relevantPaletteIdentifiers
                        .map(
                          (id) => PopupMenuItem<String>(
                            value: id,
                            child: Text(
                              AppTheme.paletteNames[id] ?? id,
                              style: kit.typography.body,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          AppBridgeListTile(
            leading: Icon(
              Icons.brightness_6_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Brightness Mode'),
            subtitle: Text(
              toBeginningOfSentenceCase(state.themeMode.name) ??
                  state.themeMode.name,
            ),
            trailing: PopupMenuButton<ThemeMode>(
              enabled: isEnabled,
              icon: Icon(
                Icons.arrow_drop_down,
                color: kit.colors.textSecondary,
              ),
              tooltip: "Select Brightness Mode",
              initialValue: state.themeMode,
              onSelected: (ThemeMode newMode) =>
                  context.read<SettingsBloc>().add(UpdateTheme(newMode)),
              itemBuilder: (context) => ThemeMode.values
                  .map(
                    (mode) => PopupMenuItem<ThemeMode>(
                      value: mode,
                      child: Text(
                        toBeginningOfSentenceCase(mode.name) ?? mode.name,
                        style: kit.typography.body,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
