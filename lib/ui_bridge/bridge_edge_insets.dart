import 'package:flutter/material.dart';

class BridgeEdgeInsets extends EdgeInsets {
  const BridgeEdgeInsets.all(super.value) : super.all();
  const BridgeEdgeInsets.symmetric({
    super.vertical = 0.0,
    super.horizontal = 0.0,
  }) : super.symmetric();
  const BridgeEdgeInsets.only({
    super.left = 0.0,
    super.top = 0.0,
    super.right = 0.0,
    super.bottom = 0.0,
  }) : super.only();
  const BridgeEdgeInsets.fromLTRB(
    super.left,
    super.top,
    super.right,
    super.bottom,
  ) : super.fromLTRB();

  static const BridgeEdgeInsets zero = BridgeEdgeInsets.only();
}
