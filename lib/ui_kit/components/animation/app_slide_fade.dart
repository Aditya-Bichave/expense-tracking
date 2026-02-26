import 'package:flutter/material.dart';

class AppSlideFade extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Offset offset;
  final Curve? curve;
  final double delay; // delay in seconds

  const AppSlideFade({
    super.key,
    required this.child,
    this.duration,
    this.offset = const Offset(0, 0.1),
    this.curve,
    this.delay = 0,
  });

  @override
  State<AppSlideFade> createState() => _AppSlideFadeState();
}

class _AppSlideFadeState extends State<AppSlideFade> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 400),
    );

    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve ?? Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve ?? Curves.easeOut),
    );

    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
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
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
