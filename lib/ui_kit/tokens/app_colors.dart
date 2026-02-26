import 'package:flutter/material.dart';

class AppColors {
  final ColorScheme _scheme;

  const AppColors(this._scheme);

  // Core Material accessors (keep for compatibility/fallback)
  Color get primary => _scheme.primary;
  Color get onPrimary => _scheme.onPrimary;
  Color get primaryContainer => _scheme.primaryContainer;
  Color get onPrimaryContainer => _scheme.onPrimaryContainer;
  Color get secondary => _scheme.secondary;
  Color get onSecondary => _scheme.onSecondary;
  Color get secondaryContainer => _scheme.secondaryContainer;
  Color get onSecondaryContainer => _scheme.onSecondaryContainer;
  Color get tertiary => _scheme.tertiary;
  Color get onTertiary => _scheme.onTertiary;
  Color get tertiaryContainer => _scheme.tertiaryContainer;
  Color get onTertiaryContainer => _scheme.onTertiaryContainer;
  Color get error => _scheme.error;
  Color get onError => _scheme.onError;
  Color get errorContainer => _scheme.errorContainer;
  Color get onErrorContainer => _scheme.onErrorContainer;
  Color get surface => _scheme.surface;
  Color get onSurface => _scheme.onSurface;
  Color get onSurfaceVariant => _scheme.onSurfaceVariant;
  Color get outline => _scheme.outline;
  Color get outlineVariant => _scheme.outlineVariant;
  Color get shadow => _scheme.shadow;
  Color get scrim => _scheme.scrim;
  Color get inverseSurface => _scheme.inverseSurface;
  Color get onInverseSurface => _scheme.onInverseSurface;
  Color get inversePrimary => _scheme.inversePrimary;

  // --- Semantic Roles (The "UI Kit" Way) ---

  /// Main background color.
  /// In dark mode, this should be a "warm dark" if configured in the scheme,
  /// otherwise it falls back to surface.
  Color get bg => _scheme.surface;

  /// Secondary background for cards, sheets, etc.
  Color get surfaceContainer => _scheme.surfaceContainer;

  /// Color for cards.
  Color get card => _scheme.surfaceContainerLow;

  /// Color for elevated surfaces (dialogs, floating sheets).
  Color get elevated => _scheme.surfaceContainerHigh;

  /// Standard border color.
  Color get border => _scheme.outline;

  /// Subtle border color for dividers or disabled states.
  Color get borderSubtle => _scheme.outlineVariant;

  /// Primary text color (high emphasis).
  Color get textPrimary => _scheme.onSurface;

  /// Secondary text color (medium emphasis).
  Color get textSecondary => _scheme.onSurfaceVariant;

  /// Muted/Disabled text color (low emphasis).
  Color get textMuted => _scheme.onSurface.withOpacity(0.38);

  /// Brand accent color.
  Color get accent => _scheme.primary;

  /// Semantic Success (Green-ish).
  /// Using tertiary as a proxy if not defined specifically, or hardcoded fallback.
  /// Ideally, the ColorScheme should have custom extensions for these,
  /// but for now we map to standard slots or fixed colors if needed.
  Color get success => Colors.green.shade600; // Customizable later

  /// Semantic Warning (Orange/Yellow-ish).
  Color get warn => Colors.orange.shade700;

  /// Semantic Danger/Error (Red-ish).
  Color get danger => _scheme.error;

  // --- Alpha Helpers ---
  Color get overlay => _scheme.shadow.withOpacity(0.1);
  Color get barrier => _scheme.scrim.withOpacity(0.5);
}
