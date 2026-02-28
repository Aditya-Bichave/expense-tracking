// lib/core/theme/app_theme.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart'; // Import the ThemeExtension class
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

// Import AppConstants

// Import Theme Configs
import 'config/theme_config_interface.dart';
import 'config/elemental_configs.dart';
import 'config/quantum_configs.dart';
import 'config/aether_configs.dart';
import 'config/stitch_configs.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

// Structure to hold both light and dark theme data (Keep as is)
class AppThemeDataPair {
  final ThemeData light;
  final ThemeData dark;
  const AppThemeDataPair({required this.light, required this.dark});
}

class AppTheme {
  // --- Palette Identifiers (Keep as is) ---
  static const String elementalPalette1 = 'elemental_soft_neutrals';
  static const String elementalPalette2 = 'elemental_ocean_calm';
  static const String elementalPalette3 = 'elemental_light_airy';
  static const String elementalPalette4 =
      'elemental_deep_dark'; // Renamed identifier slightly

  static const String quantumPalette1 = 'quantum_cyan_dark';
  static const String quantumPalette2 = 'quantum_cool_blue';
  static const String quantumPalette3 = 'quantum_warm_red';
  static const String quantumPalette4 = 'quantum_neutral_tech';

  static const String aetherPalette1 = 'aether_starfield';
  static const String aetherPalette2 = 'aether_garden';
  static const String aetherPalette3 = 'aether_mystic';
  static const String aetherPalette4 = 'aether_calm_sky';

  static const String stitchPalette1 = 'stitch_neon_green';

  // --- Palette Names (Display Names) ---
  static final Map<String, String> paletteNames = {
    elementalPalette1: 'Soft Neutrals',
    elementalPalette2: 'Ocean Calm',
    elementalPalette3: 'Light & Airy',
    elementalPalette4: 'Elemental Dark',
    quantumPalette1: 'Cyan Tech',
    quantumPalette2: 'Cool Blue',
    quantumPalette3: 'Warm Red',
    quantumPalette4: 'Neutral Tech',
    aetherPalette1: 'Starfield',
    aetherPalette2: 'Garden',
    aetherPalette3: 'Mystic',
    aetherPalette4: 'Calm Sky',
    stitchPalette1: 'Stitch Neon',
  };

  // --- UI Mode Names (Keep as is) ---
  static final Map<UIMode, String> uiModeNames = {
    UIMode.elemental: 'Elemental',
    UIMode.quantum: 'Quantum',
    UIMode.aether: 'Aether',
    UIMode.stitch: 'Stitch',
  };

  // --- Central Factory Method (Refactored) ---
  static AppThemeDataPair buildTheme(UIMode mode, String paletteIdentifier) {
    // 1. Get the configuration object for the mode and palette
    final IThemePaletteConfig config = _getConfigForMode(
      mode,
      paletteIdentifier,
    );

    // 2. Build the custom theme extensions
    final AppModeTheme lightModeTheme = _buildModeThemeExtension(
      config,
      Brightness.light,
    );
    final AppModeTheme darkModeTheme = _buildModeThemeExtension(
      config,
      Brightness.dark,
    );

    // 3. Build the final ThemeData using the SINGLE base builder
    final ThemeData lightTheme = _buildBaseThemeData(
      config.lightColorScheme,
      lightModeTheme,
    );
    final ThemeData darkTheme = _buildBaseThemeData(
      config.darkColorScheme,
      darkModeTheme,
    );

    return AppThemeDataPair(light: lightTheme, dark: darkTheme);
  }

  // --- Helper to get Config ---
  static IThemePaletteConfig _getConfigForMode(UIMode mode, String paletteId) {
    // Ensure paletteId corresponds to the selected mode, or provide a default
    String validPaletteId = paletteId;
    if (!paletteId.startsWith(mode.name)) {
      // If the stored palette ID doesn't match the current mode, select a default
      switch (mode) {
        case UIMode.elemental:
          validPaletteId = elementalPalette1;
          break;
        case UIMode.quantum:
          validPaletteId = quantumPalette1;
          break;
        case UIMode.aether:
          validPaletteId = aetherPalette1;
          break;
        case UIMode.stitch:
          validPaletteId = stitchPalette1;
          break;
      }
    }

    switch (mode) {
      case UIMode.elemental:
        return ElementalConfigs.getConfig(validPaletteId);
      case UIMode.quantum:
        return QuantumConfigs.getConfig(validPaletteId);
      case UIMode.aether:
        return AetherConfigs.getConfig(validPaletteId);
      case UIMode.stitch:
        return StitchConfigs.getConfig(validPaletteId);
    }
  }

  // --- Helper to build AppModeTheme from Config (Remains the same) ---
  static AppModeTheme _buildModeThemeExtension(
    IThemePaletteConfig config,
    Brightness brightness,
  ) {
    final assets = brightness == Brightness.light
        ? config.lightAssets
        : config.darkAssets;
    final incomeGlow = brightness == Brightness.light
        ? config.incomeGlowColorLight
        : config.incomeGlowColorDark;
    final expenseGlow = brightness == Brightness.light
        ? config.expenseGlowColorLight
        : config.expenseGlowColorDark;

    return AppModeTheme(
      modeId: config.paletteIdentifier,
      layoutDensity: config.layoutDensity,
      cardStyle: config.cardStyle,
      assets: assets,
      preferDataTableForLists: config.preferDataTableForLists,
      primaryAnimationDuration: config.primaryAnimationDuration,
      listEntranceAnimation: config.listEntranceAnimation,
      incomeGlowColor: incomeGlow,
      expenseGlowColor: expenseGlow,
    );
  }

  // --- SINGLE Base Theme Builder (Consolidated) ---
  static ThemeData _buildBaseThemeData(
    ColorScheme colorScheme,
    AppModeTheme modeTheme,
  ) {
    // Determine Font based on mode or config (Example using modeTheme)
    TextTheme baseTextTheme;
    // Infer mode from palette ID prefix
    final String modePrefix = modeTheme.modeId.split('_')[0];

    switch (modePrefix) {
      case 'quantum':
        baseTextTheme = colorScheme.brightness == Brightness.light
            ? GoogleFonts.robotoMonoTextTheme(ThemeData.light().textTheme)
            : GoogleFonts.robotoMonoTextTheme(ThemeData.dark().textTheme);
        break;
      case 'aether':
        baseTextTheme = colorScheme.brightness == Brightness.light
            ? GoogleFonts.quicksandTextTheme(ThemeData.light().textTheme)
            : GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme);
        break;
      case 'stitch':
      case 'elemental':
      default:
        baseTextTheme = colorScheme.brightness == Brightness.light
            ? GoogleFonts.interTextTheme(ThemeData.light().textTheme)
            : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
        break;
    }

    // Apply common and mode-specific text theme tweaks
    final textTheme = baseTextTheme
        .copyWith(
          // Common tweaks
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          // Mode-specific tweaks
          bodySmall: modePrefix == 'quantum'
              ? baseTextTheme.bodySmall?.copyWith(fontSize: 11)
              : baseTextTheme.bodySmall,
        )
        .apply(
          // Apply base colors
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    // Visual Density based on modeTheme
    VisualDensity visualDensity;
    switch (modeTheme.layoutDensity) {
      case LayoutDensity.compact:
        visualDensity = VisualDensity.compact;
        break;
      case LayoutDensity.comfortable:
        visualDensity = VisualDensity.standard; // Or comfortable if defined
        break;
      case LayoutDensity.spacious:
        visualDensity = VisualDensity.comfortable; // Or define spacious
        break;
    }

    // Base ThemeData
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: visualDensity,
      scaffoldBackgroundColor: colorScheme.background,

      // --- Component Themes (Configure using colorScheme and modeTheme) ---
      cardTheme: CardThemeData(
        elevation: modeTheme.cardStyle == CardStyle.flat
            ? 0
            : (modeTheme.cardStyle == CardStyle.floating
                  ? 6.0
                  : (modeTheme.cardStyle == CardStyle.glass ? 0 : 1.5)),
        margin: modeTheme.layoutDensity == LayoutDensity.compact
            ? const EdgeInsets.symmetric(
                horizontal: context.space.sm,
                vertical: context.space.xs,
              )
            : const EdgeInsets.symmetric(
                horizontal: context.space.lg,
                vertical: context.space.sm,
              ),
        shape: RoundedRectangleBorder(
          borderRadius: BridgeBorderRadius.circular(
            modeTheme.cardStyle == CardStyle.flat
                ? 8
                : (modeTheme.layoutDensity == LayoutDensity.spacious ? 20 : 16),
          ),
        ),
        color: modePrefix == 'aether'
            ? colorScheme.surfaceVariant.withOpacity(0.85)
            : (modePrefix == 'quantum'
                  ? colorScheme.surface
                  : (modePrefix == 'stitch'
                        ? Colors.transparent
                        : colorScheme.surfaceContainer)),
        clipBehavior: (modePrefix == 'aether' || modePrefix == 'stitch')
            ? Clip.antiAlias
            : Clip.none,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: modeTheme.layoutDensity == LayoutDensity.compact
            ? const EdgeInsets.symmetric(
                horizontal: context.space.md,
                vertical: context.space.xxs,
              )
            : const EdgeInsets.symmetric(
                horizontal: context.space.lg,
                vertical: context.space.xs,
              ),
        dense: modeTheme.layoutDensity == LayoutDensity.compact,
        minVerticalPadding: modeTheme.layoutDensity == LayoutDensity.compact
            ? 8
            : 12,
        horizontalTitleGap: modeTheme.layoutDensity == LayoutDensity.compact
            ? 8
            : 16,
        iconColor: colorScheme.onSurfaceVariant, // Default icon color
        titleTextStyle: textTheme.bodyLarge, // Default title style
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ), // Default subtitle style
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BridgeBorderRadius.circular(
            modePrefix == 'quantum' ? 6.0 : 12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: (modePrefix == 'aether' || modePrefix == 'stitch')
                ? Colors.transparent
                : colorScheme.outlineVariant,
            width: 0.8,
          ),
          borderRadius: BridgeBorderRadius.circular(
            modePrefix == 'quantum'
                ? 6.0
                : ((modePrefix == 'aether' || modePrefix == 'stitch')
                      ? 16
                      : 12),
          ),
        ),
        focusedBorder: (modePrefix == 'aether' || modePrefix == 'stitch')
            ? OutlineInputBorder(
                borderRadius: Bridgecontext.kit.radii.large,
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              )
            : OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                borderRadius: BridgeBorderRadius.circular(
                  modePrefix == 'quantum' ? 6.0 : 12,
                ),
              ),
        filled: modePrefix == 'aether' || modePrefix == 'stitch',
        fillColor: (modePrefix == 'aether' || modePrefix == 'stitch')
            ? colorScheme.surface.withOpacity(0.05) // Generic low opacity fill
            : null,
        contentPadding: modeTheme.layoutDensity == LayoutDensity.compact
            ? const EdgeInsets.symmetric(
                horizontal: context.space.md,
                vertical: context.space.sm,
              )
            : const EdgeInsets.symmetric(
                horizontal: context.space.lg,
                vertical: context.space.md,
              ),
        isDense: modeTheme.layoutDensity == LayoutDensity.compact,
        floatingLabelBehavior: modePrefix == 'quantum'
            ? FloatingLabelBehavior.always
            : FloatingLabelBehavior.auto,
        floatingLabelStyle: (modePrefix == 'aether' || modePrefix == 'stitch')
            ? BridgeTextStyle(color: colorScheme.primary)
            : null,
        prefixIconColor: colorScheme.onSurfaceVariant,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: modePrefix == 'aether'
              ? colorScheme.primaryContainer
              : colorScheme.primary,
          foregroundColor: modePrefix == 'aether'
              ? colorScheme.onPrimaryContainer
              : colorScheme.onPrimary,
          padding: modeTheme.layoutDensity == LayoutDensity.compact
              ? const EdgeInsets.symmetric(
                  horizontal: context.space.lg,
                  vertical: context.space.sm,
                )
              : const EdgeInsets.symmetric(
                  horizontal: context.space.xxl,
                  vertical: context.space.md,
                ),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BridgeBorderRadius.circular(
              modePrefix == 'quantum' ? 6.0 : 12,
            ),
          ),
          elevation: modeTheme.cardStyle == CardStyle.flat
              ? 0
              : (modePrefix == 'aether' ? 4 : 2),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: modePrefix == 'aether'
            ? colorScheme.tertiaryContainer
            : colorScheme.primaryContainer,
        foregroundColor: modePrefix == 'aether'
            ? colorScheme.onTertiaryContainer
            : colorScheme.onPrimaryContainer,
        elevation: modeTheme.cardStyle == CardStyle.flat
            ? 0
            : (modePrefix == 'aether' ? 6.0 : 4),
        shape: RoundedRectangleBorder(
          borderRadius: BridgeBorderRadius.circular(
            modePrefix == 'aether' ? 20 : 16,
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: (modePrefix == 'aether' || modePrefix == 'stitch')
            ? colorScheme.background.withOpacity(0.8) // Glass effect base
            : colorScheme.surfaceContainerHighest, // Adjusted BG
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(
          modePrefix == 'quantum' ? 0.6 : 0.7,
        ),
        elevation:
            (modeTheme.cardStyle == CardStyle.flat ||
                modeTheme.cardStyle == CardStyle.glass)
            ? 0
            : 2,
        selectedLabelStyle: modePrefix == 'quantum'
            ? textTheme.labelSmall
            : textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: textTheme.labelSmall,
        selectedIconTheme: IconThemeData(
          size: modePrefix == 'quantum' ? 20 : 24,
        ), // Adjusted size
        unselectedIconTheme: IconThemeData(
          size: modePrefix == 'quantum' ? 20 : 24,
        ), // Adjusted size
      ),

      dividerTheme: DividerThemeData(
        color: modePrefix == 'aether'
            ? colorScheme.primary.withOpacity(0.3)
            : colorScheme.outlineVariant,
        thickness: modePrefix == 'aether' ? 1 : 0.8,
        space: modePrefix == 'aether' ? 24 : 1,
        indent: modePrefix == 'aether' ? 20 : 0,
        endIndent: modePrefix == 'aether' ? 20 : 0,
      ),

      dataTableTheme: modeTheme.preferDataTableForLists
          ? DataTableThemeData(
              columnSpacing: 12,
              headingRowHeight: 36,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              headingTextStyle: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              dataTextStyle: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              dividerThickness: 0.8,
              dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.selected)) {
                  return colorScheme.primaryContainer.withOpacity(0.2);
                }
                return null;
              }),
            )
          : null,

      // Add the AppModeTheme extension
      extensions: <ThemeExtension<dynamic>>[
        modeTheme,
        AppKitTheme(
          colors: AppColors(colorScheme),
          typography: AppTypography(textTheme),
          spacing: const AppSpacing(),
          radii: AppRadii(
            sm: modePrefix == 'quantum' ? 4.0 : 8.0,
            md: modePrefix == 'quantum'
                ? 6.0
                : (modePrefix == 'aether' || modePrefix == 'stitch'
                      ? 16.0
                      : 12.0),
            lg: modePrefix == 'aether' ? 20.0 : 16.0,
            xl: 24.0,
          ),
          motion: const AppMotion(),
          shadows: AppShadows(
            isDark: colorScheme.brightness == Brightness.dark,
          ),
        ),
      ],
    );
  }
}
