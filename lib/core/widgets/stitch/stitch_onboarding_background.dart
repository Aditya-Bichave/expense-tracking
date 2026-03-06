import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';

class StitchOnboardingBackground extends StatelessWidget {
  final Widget child;

  const StitchOnboardingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Stack(
      children: [
        // Base Background
        Container(color: theme.colorScheme.background),
        // Mesh Gradient Orbs
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BridgeDecoration(
              shape: BoxShape.circle,
              color: primary.withOpacity(0.15),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BridgeDecoration(
              shape: BoxShape.circle,
              color: primary.withOpacity(0.1),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
