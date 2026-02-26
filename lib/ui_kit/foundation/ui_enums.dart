// lib/ui_kit/foundation/ui_enums.dart
// This file centralizes the shared enums for the UI Kit components.
// All new components should rely on these variants where possible.

/// Standard sizing for components.
/// Not all components support all sizes.
enum UiSize {
  /// Extra small (e.g., tags, tiny buttons)
  xs,

  /// Small (e.g., dense lists, secondary actions)
  sm,

  /// Medium (Default for most inputs/buttons)
  md,

  /// Large (Primary actions, key inputs)
  lg,

  /// Extra large (Hero sections)
  xl,
}

/// Standard visual variants for components.
enum UiVariant {
  /// The main, high-emphasis style (e.g., filled button)
  primary,

  /// The secondary, medium-emphasis style (e.g., outlined button)
  secondary,

  /// Low-emphasis or transparent style (e.g., text button)
  ghost,

  /// Destructive action style (e.g., delete button)
  destructive,

  /// Secondary destructive style (e.g., outlined delete button)
  destructiveSecondary,

  /// Success state style
  success,

  /// Warning state style
  warning,

  /// Info state style
  info,
}

/// Standard state flags for components.
/// These can be combined or used individually depending on component complexity.
enum UiState {
  enabled,
  disabled,
  loading,
  error,
  focused,
  hovered,
  pressed,
  selected,
}

/// Standard spacing tokens alias for cleaner usage if needed.
enum UiSpacing { xxs, xs, sm, md, lg, xl, xxl, xxxl }
