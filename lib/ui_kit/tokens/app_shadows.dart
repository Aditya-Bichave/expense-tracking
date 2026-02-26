import 'package:flutter/material.dart';

class AppShadows {
  final bool _isDark;

  const AppShadows({bool isDark = false}) : _isDark = isDark;

  List<BoxShadow> get sm => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ];

  List<BoxShadow> get md => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ];

  List<BoxShadow> get lg => _isDark
      ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -3,
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -2,
          ),
        ];

  /// Subtle glow for dark mode, barely visible shadow for light
  List<BoxShadow> get glow => _isDark
      ? [
          BoxShadow(
            color: const Color(0xFF64B5F6).withOpacity(0.15), // Light Blue tint
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ]
      : sm;
}
