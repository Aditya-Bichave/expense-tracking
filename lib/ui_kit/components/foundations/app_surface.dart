import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppSurface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final VoidCallback? onTap;

  const AppSurface({
    super.key,
    required this.child,
    this.color,
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
    this.elevation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    Widget surface = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? kit.colors.surfaceContainer,
        borderRadius: borderRadius ?? kit.radii.medium,
        border: border,
        boxShadow: elevation != null && elevation! > 0 ? kit.shadows.sm : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: surface,
      );
    }

    return surface;
  }
}
