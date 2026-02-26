import 'package:flutter/material.dart';

class AppRadii {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;

  const AppRadii({
    this.xs = 4.0,
    this.sm = 8.0,
    this.md = 12.0,
    this.lg = 16.0,
    this.xl = 24.0,
    this.full = 999.0,
  });

  static const standard = AppRadii();

  // Raw Radius
  Radius get rXs => Radius.circular(xs);
  Radius get rSm => Radius.circular(sm);
  Radius get rMd => Radius.circular(md);
  Radius get rLg => Radius.circular(lg);
  Radius get rXl => Radius.circular(xl);

  // BorderRadius
  BorderRadius get xsmall => BorderRadius.circular(xs);
  BorderRadius get small => BorderRadius.circular(sm);
  BorderRadius get medium => BorderRadius.circular(md);
  BorderRadius get large => BorderRadius.circular(lg);
  BorderRadius get extraLarge => BorderRadius.circular(xl);
  BorderRadius get circular => BorderRadius.circular(full);

  // Semantic Radii
  BorderRadius get card => medium;
  BorderRadius get sheet => BorderRadius.vertical(top: Radius.circular(lg));
  BorderRadius get button => medium;
  BorderRadius get chip => circular;
}
