import 'package:flutter/material.dart';

class BridgeBorderRadius extends BorderRadius {
  const BridgeBorderRadius.all(super.radius) : super.all();
  BridgeBorderRadius.circular(super.radius) : super.circular();
  const BridgeBorderRadius.only({
    super.topLeft = Radius.zero,
    super.topRight = Radius.zero,
    super.bottomLeft = Radius.zero,
    super.bottomRight = Radius.zero,
  }) : super.only();
  const BridgeBorderRadius.vertical({
    super.top = Radius.zero,
    super.bottom = Radius.zero,
  }) : super.vertical();
  const BridgeBorderRadius.horizontal({
    super.left = Radius.zero,
    super.right = Radius.zero,
  }) : super.horizontal();
}
