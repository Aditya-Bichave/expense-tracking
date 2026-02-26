import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppFadeScale extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Curve? curve;

  const AppFadeScale({
    super.key,
    required this.child,
    this.duration,
    this.curve,
  });

  @override
  State<AppFadeScale> createState() => _AppFadeScaleState();
}

class _AppFadeScaleState extends State<AppFadeScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final kit = const AppMotion(); // Can't access context here easily, use default
    // Wait, I can't access context in initState.
    // I'll set it up in didChangeDependencies or build, but reusing controller is better.
    // I'll just use a default or wait for build.

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 300),
    );

    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve ?? Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve ?? Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
