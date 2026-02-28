// lib/core/widgets/app_card.dart
import 'dart:ui';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

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
    final isGlass = modeTheme?.cardStyle == CardStyle.glass;

    // Determine properties: Use override -> theme.cardTheme -> modeTheme -> hardcoded fallback
    final cardMargin =
        margin ??
        theme.cardTheme.margin ??
        modeTheme?.cardOuterPadding ??
        const BridgeEdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

    // Card itself doesn't have padding in theme. Apply padding via Padding widget.
    // Use provided padding -> modeTheme padding -> fallback.
    final cardInnerPadding =
        padding ??
        modeTheme?.cardInnerPadding ??
        const BridgeEdgeInsets.all(16.0);

    // If glass, force transparent color unless overridden
    final cardColor = isGlass
        ? (color ?? Colors.transparent)
        : (color ?? theme.cardTheme.color ?? theme.colorScheme.surface);

    ShapeBorder? cardShape = shape ?? theme.cardTheme.shape;

    // If glass, ensure border exists if not explicitly set
    if (isGlass &&
        cardShape is RoundedRectangleBorder &&
        cardShape.side == BorderSide.none) {
      // Add subtle border for glass
      cardShape = cardShape.copyWith(
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      );
    }

    final cardElevation = elevation ?? theme.cardTheme.elevation;
    final cardClipBehavior = theme.cardTheme.clipBehavior ?? clipBehavior;

    // Ensure elevation is not null for Card widget (0 for flat/glass)
    final double finalElevation =
        cardElevation ??
        (modeTheme?.cardStyle == CardStyle.flat || isGlass ? 0 : 2);

    // Wrap the child with the determined padding
    Widget cardContent = Padding(padding: cardInnerPadding, child: child);

    if (isGlass) {
      return BridgeCard(
        margin: cardMargin,
        elevation: finalElevation,
        shape: cardShape,
        color: cardColor,
        clipBehavior: cardClipBehavior,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
            onTap != null
                ? InkWell(
                    onTap: onTap,
                    // Use theme highlight/splash or default
                    splashColor: theme.colorScheme.primary.withOpacity(0.1),
                    highlightColor: theme.colorScheme.primary.withOpacity(0.05),
                    child: cardContent,
                  )
                : cardContent,
          ],
        ),
      );
    }

    return BridgeCard(
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
