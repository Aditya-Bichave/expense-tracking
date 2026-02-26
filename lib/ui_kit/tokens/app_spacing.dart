import 'package:flutter/material.dart';

class AppSpacing {
  // Base scale
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  const AppSpacing({
    this.xxs = 2.0,
    this.xs = 4.0,
    this.sm = 8.0,
    this.md = 12.0,
    this.lg = 16.0,
    this.xl = 20.0,
    this.xxl = 24.0,
    this.xxxl = 32.0,
  });

  static const standard = AppSpacing();

  // Insets helpers
  EdgeInsets get allXxs => EdgeInsets.all(xxs);
  EdgeInsets get allXs => EdgeInsets.all(xs);
  EdgeInsets get allSm => EdgeInsets.all(sm);
  EdgeInsets get allMd => EdgeInsets.all(md);
  EdgeInsets get allLg => EdgeInsets.all(lg);
  EdgeInsets get allXl => EdgeInsets.all(xl);
  EdgeInsets get allXxl => EdgeInsets.all(xxl);

  // Horizontal
  EdgeInsets get hXxs => EdgeInsets.symmetric(horizontal: xxs);
  EdgeInsets get hXs => EdgeInsets.symmetric(horizontal: xs);
  EdgeInsets get hSm => EdgeInsets.symmetric(horizontal: sm);
  EdgeInsets get hMd => EdgeInsets.symmetric(horizontal: md);
  EdgeInsets get hLg => EdgeInsets.symmetric(horizontal: lg);
  EdgeInsets get hXl => EdgeInsets.symmetric(horizontal: xl);
  EdgeInsets get hXxl => EdgeInsets.symmetric(horizontal: xxl);

  // Vertical
  EdgeInsets get vXxs => EdgeInsets.symmetric(vertical: xxs);
  EdgeInsets get vXs => EdgeInsets.symmetric(vertical: xs);
  EdgeInsets get vSm => EdgeInsets.symmetric(vertical: sm);
  EdgeInsets get vMd => EdgeInsets.symmetric(vertical: md);
  EdgeInsets get vLg => EdgeInsets.symmetric(vertical: lg);
  EdgeInsets get vXl => EdgeInsets.symmetric(vertical: xl);
  EdgeInsets get vXxl => EdgeInsets.symmetric(vertical: xxl);

  // Gap helpers (SizedBox)
  SizedBox get gapXxs => SizedBox(width: xxs, height: xxs);
  SizedBox get gapXs => SizedBox(width: xs, height: xs);
  SizedBox get gapSm => SizedBox(width: sm, height: sm);
  SizedBox get gapMd => SizedBox(width: md, height: md);
  SizedBox get gapLg => SizedBox(width: lg, height: lg);
  SizedBox get gapXl => SizedBox(width: xl, height: xl);
  SizedBox get gapXxl => SizedBox(width: xxl, height: xxl);
  SizedBox get gapXxxl => SizedBox(width: xxxl, height: xxxl);

  // Specific direction gaps (width)
  SizedBox get wXxs => SizedBox(width: xxs);
  SizedBox get wXs => SizedBox(width: xs);
  SizedBox get wSm => SizedBox(width: sm);
  SizedBox get wMd => SizedBox(width: md);
  SizedBox get wLg => SizedBox(width: lg);
  SizedBox get wXl => SizedBox(width: xl);
  SizedBox get wXxl => SizedBox(width: xxl);

  // Specific direction gaps (height)
  SizedBox get hgapXxs => SizedBox(height: xxs);
  SizedBox get hgapXs => SizedBox(height: xs);
  SizedBox get hgapSm => SizedBox(height: sm);
  SizedBox get hgapMd => SizedBox(height: md);
  SizedBox get hgapLg => SizedBox(height: lg);
  SizedBox get hgapXl => SizedBox(height: xl);
  SizedBox get hgapXxl => SizedBox(height: xxl);
}
