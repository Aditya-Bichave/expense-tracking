import 'package:flutter/material.dart';

class AppSpacing {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  const AppSpacing({
    this.xs = 4.0,
    this.sm = 8.0,
    this.md = 16.0,
    this.lg = 24.0,
    this.xl = 32.0,
    this.xxl = 48.0,
  });

  // Standard instance
  static const standard = AppSpacing();

  // Insets helpers
  EdgeInsets get allXs => EdgeInsets.all(xs);
  EdgeInsets get allSm => EdgeInsets.all(sm);
  EdgeInsets get allMd => EdgeInsets.all(md);
  EdgeInsets get allLg => EdgeInsets.all(lg);

  EdgeInsets get hXs => EdgeInsets.symmetric(horizontal: xs);
  EdgeInsets get hSm => EdgeInsets.symmetric(horizontal: sm);
  EdgeInsets get hMd => EdgeInsets.symmetric(horizontal: md);
  EdgeInsets get hLg => EdgeInsets.symmetric(horizontal: lg);

  EdgeInsets get vXs => EdgeInsets.symmetric(vertical: xs);
  EdgeInsets get vSm => EdgeInsets.symmetric(vertical: sm);
  EdgeInsets get vMd => EdgeInsets.symmetric(vertical: md);
  EdgeInsets get vLg => EdgeInsets.symmetric(vertical: lg);
}
