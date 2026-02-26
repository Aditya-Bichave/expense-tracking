import 'package:flutter/material.dart';

class AppMotion {
  final Duration fast;
  final Duration normal;
  final Duration slow;

  final Curve standard;
  final Curve emphasized;
  final Curve overshoot;

  const AppMotion({
    this.fast = const Duration(milliseconds: 200),
    this.normal = const Duration(milliseconds: 350),
    this.slow = const Duration(milliseconds: 500),
    this.standard = Curves.easeInOut,
    this.emphasized = Curves.easeInOutCubicEmphasized,
    this.overshoot = const Cubic(0.34, 1.56, 0.64, 1.0), // Spring-like
  });

  static const standardInstance = AppMotion();
}
