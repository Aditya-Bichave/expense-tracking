// lib/core/widgets/app_card.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? margin; // Override theme margin
  final EdgeInsets? padding; // Override theme inner padding
  final Clip clipBehavior;
  final Color? color; // Override theme color
  final ShapeBorder? shape; // Override theme shape
  final double? elevation; // Override theme elevation

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    this.color,
    this.shape,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    // Determine properties: Use override -> theme.cardTheme -> modeTheme -> hardcoded fallback
    final cardMargin = margin ??
        theme.cardTheme.margin ??
        modeTheme?.cardOuterPadding ??
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    // --- CORRECTED PADDING LOGIC ---
    // Card itself doesn't have padding in theme. Apply padding via Padding widget.
    // Use provided padding -> modeTheme padding -> fallback.
    final cardInnerPadding =
        padding ?? modeTheme?.cardInnerPadding ?? const EdgeInsets.all(16.0);
    // -------------------------------
    final cardColor =
        color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final cardShape = shape ?? theme.cardTheme.shape;
    final cardElevation = elevation ?? theme.cardTheme.elevation;
    final cardClipBehavior = theme.cardTheme.clipBehavior ?? clipBehavior;

    // Wrap the child with the determined padding
    Widget cardContent = Padding(
      padding: cardInnerPadding,
      child: child,
    );

    // Ensure elevation is not null for Card widget
    final double finalElevation =
        cardElevation ?? (modeTheme?.cardStyle == CardStyle.flat ? 0 : 2);

    return Card(
      margin: cardMargin,
      elevation: finalElevation,
      shape: cardShape,
      color: cardColor,
      clipBehavior: cardClipBehavior,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              // Optional: Apply highlight/splash from theme if needed
              // highlightColor: theme.highlightColor.withOpacity(0.1),
              // splashColor: theme.splashColor.withOpacity(0.1),
              child: cardContent,
            )
          : cardContent,
    );
  }
}
