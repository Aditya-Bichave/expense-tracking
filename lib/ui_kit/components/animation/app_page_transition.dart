import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppPageTransition {
  static Route<T> sharedAxis<T>(Widget page) {
    // Simple Cupertino style wrapper for now, mimicking standard transitions.
    // For fancier shared axis, we'd need 'animations' package.
    // Constraint: "No new dependencies unless truly necessary".
    // So we use standard CupertinoPageRoute which is "iOS-cozy".
    return CupertinoPageRoute<T>(builder: (_) => page);
  }
}
