import 'package:flutter/material.dart';

class AppColors {
  final ColorScheme _scheme;

  const AppColors(this._scheme);

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

  // Semantic aliases for clarity
  Color get background => _scheme.surface;
  Color get text => _scheme.onSurface;
  Color get textSecondary => _scheme.onSurfaceVariant;
  Color get border => _scheme.outline;
  Color get borderSubtle => _scheme.outlineVariant;
}
