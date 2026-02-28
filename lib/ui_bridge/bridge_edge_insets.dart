import 'package:flutter/material.dart';

class EdgeInsets extends EdgeInsets {
  const EdgeInsets.all(super.value) : super.all();
  const EdgeInsets.symmetric({super.vertical = 0.0, super.horizontal = 0.0})
    : super.symmetric();
  const EdgeInsets.only({
    super.left = 0.0,
    super.top = 0.0,
    super.right = 0.0,
    super.bottom = 0.0,
  }) : super.only();
  const EdgeInsets.fromLTRB(super.left, super.top, super.right, super.bottom)
    : super.fromLTRB();

  static const EdgeInsets zero = EdgeInsets.only();
}
