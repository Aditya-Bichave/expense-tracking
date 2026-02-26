import 'package:flutter/material.dart';

class AppTypography {
  final TextTheme _textTheme;

  const AppTypography(this._textTheme);

  TextStyle get displayLarge => _textTheme.displayLarge!;
  TextStyle get displayMedium => _textTheme.displayMedium!;
  TextStyle get displaySmall => _textTheme.displaySmall!;

  TextStyle get headlineLarge => _textTheme.headlineLarge!;
  TextStyle get headlineMedium => _textTheme.headlineMedium!;
  TextStyle get headlineSmall => _textTheme.headlineSmall!;

  TextStyle get titleLarge => _textTheme.titleLarge!;
  TextStyle get titleMedium => _textTheme.titleMedium!;
  TextStyle get titleSmall => _textTheme.titleSmall!;

  TextStyle get bodyLarge => _textTheme.bodyLarge!;
  TextStyle get bodyMedium => _textTheme.bodyMedium!;
  TextStyle get bodySmall => _textTheme.bodySmall!;

  TextStyle get labelLarge => _textTheme.labelLarge!;
  TextStyle get labelMedium => _textTheme.labelMedium!;
  TextStyle get labelSmall => _textTheme.labelSmall!;
}
