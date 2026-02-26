import 'package:flutter/material.dart';

class AppLayout {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Max widths
  static const double maxContentWidth = 1000;
  static const double maxTextWidth = 600;

  // Methods
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Returns a constrained width box for web/desktop centering
  static BoxConstraints get contentConstraints =>
      const BoxConstraints(maxWidth: maxContentWidth);
}
