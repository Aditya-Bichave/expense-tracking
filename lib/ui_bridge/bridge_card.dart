import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';

/// Bridge adapter for cards.
/// Wraps [AppCard].
class BridgeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const BridgeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}
