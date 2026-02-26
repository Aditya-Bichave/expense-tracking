import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'dart:ui';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final bool glass;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final modeTheme = context.modeTheme;

    // Determine effective style from props or theme
    final isGlass = glass || (modeTheme?.cardStyle == CardStyle.glass);

    // Determine elevation based on style if not provided
    double effectiveElevation = elevation ?? 0;
    if (elevation == null && !isGlass) {
       if (modeTheme?.cardStyle == CardStyle.elevated) {
         effectiveElevation = 2;
       } else if (modeTheme?.cardStyle == CardStyle.floating) {
         effectiveElevation = 6;
       }
       // flat is 0
    }

    Widget cardContent = Padding(
      padding: padding ?? kit.spacing.allMd,
      child: child,
    );

    if (isGlass) {
      return Container(
        margin: margin ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: (color ?? kit.colors.surface).withOpacity(0.7),
          borderRadius: kit.radii.card,
          border: Border.all(
            color: kit.colors.borderSubtle.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: kit.shadows.sm,
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: onTap != null
              ? InkWell(onTap: onTap, child: cardContent)
              : cardContent,
        ),
      );
    }

    return Card(
      elevation: effectiveElevation,
      margin: margin ?? EdgeInsets.zero,
      color: color ?? kit.colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: kit.radii.card,
        side: BorderSide(color: kit.colors.borderSubtle, width: 0.5),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: kit.radii.card,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
