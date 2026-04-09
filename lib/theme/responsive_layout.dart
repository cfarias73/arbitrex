import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double maxWidth = 480;
  static const double maxFeedWidth = 800;
  static const double maxContentWidth = 1200;

  static Widget constrained(Widget child, {double width = maxWidth}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;
}
