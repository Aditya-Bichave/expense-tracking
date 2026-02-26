import 'package:flutter/material.dart';

class AppRadii {
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;

  const AppRadii({
    this.sm = 8.0,
    this.md = 12.0,
    this.lg = 16.0,
    this.xl = 24.0,
    this.full = 999.0,
  });

  static const standard = AppRadii();

  BorderRadius get small => BorderRadius.circular(sm);
  BorderRadius get medium => BorderRadius.circular(md);
  BorderRadius get large => BorderRadius.circular(lg);
  BorderRadius get extraLarge => BorderRadius.circular(xl);
  BorderRadius get circular => BorderRadius.circular(full);
}
