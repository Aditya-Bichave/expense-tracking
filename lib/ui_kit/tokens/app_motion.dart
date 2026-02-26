import 'package:flutter/material.dart';

class AppMotion {
  final Duration short;
  final Duration medium;
  final Duration long;
  final Curve defaultCurve;

  const AppMotion({
    this.short = const Duration(milliseconds: 150),
    this.medium = const Duration(milliseconds: 300),
    this.long = const Duration(milliseconds: 500),
    this.defaultCurve = Curves.easeInOut,
  });

  static const standard = AppMotion();
}
