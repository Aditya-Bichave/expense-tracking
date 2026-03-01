import 'package:flutter/material.dart';

class BridgeEdgeInsets extends EdgeInsets {
  const BridgeEdgeInsets.all(super.value) : super.all();
  const BridgeEdgeInsets.symmetric({super.vertical, super.horizontal})
    : super.symmetric();
  const BridgeEdgeInsets.only({
    super.left,
    super.top,
    super.right,
    super.bottom,
  }) : super.only();
  const BridgeEdgeInsets.fromLTRB(
    super.left,
    super.top,
    super.right,
    super.bottom,
  ) : super.fromLTRB();

  static const BridgeEdgeInsets zero = BridgeEdgeInsets.all(0.0);
}
