import 'package:flutter/material.dart';

class AppTypography {
  final TextTheme _textTheme;

  const AppTypography(this._textTheme);

  // Core semantic styles

  /// Huge display text for headers or hero sections
  TextStyle get display => _textTheme.displaySmall!.copyWith(
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  /// Standard screen title
  TextStyle get title => _textTheme.headlineSmall!.copyWith(
    fontWeight: FontWeight.w600,
  );

  /// Section headline
  TextStyle get headline => _textTheme.titleLarge!.copyWith(
    fontWeight: FontWeight.w600,
  );

  /// Regular body text
  TextStyle get body => _textTheme.bodyMedium!;

  /// Emphasized body text (bold)
  TextStyle get bodyStrong => _textTheme.bodyMedium!.copyWith(
    fontWeight: FontWeight.w700,
  );

  /// Small caption text
  TextStyle get caption => _textTheme.bodySmall!;

  /// All caps overline text for labels
  TextStyle get overline => _textTheme.labelSmall!.copyWith(
    letterSpacing: 1.0,
    fontWeight: FontWeight.w600,
  );

  // Mapping existing ones for compatibility if needed,
  // but preferring the semantic ones above.
  TextStyle get labelLarge => _textTheme.labelLarge!;
  TextStyle get labelMedium => _textTheme.labelMedium!;
  TextStyle get labelSmall => _textTheme.labelSmall!;
  TextStyle get bodyLarge => _textTheme.bodyLarge!;
  TextStyle get bodyMedium => _textTheme.bodyMedium!;
  TextStyle get bodySmall => _textTheme.bodySmall!;
}
