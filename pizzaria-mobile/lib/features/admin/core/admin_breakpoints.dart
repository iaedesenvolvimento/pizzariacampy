import 'package:flutter/widgets.dart';

enum AdminLayoutSize { compact, medium, expanded }

abstract final class AdminBreakpoints {
  static const compactMax = 600.0;
  static const mediumMax = 1024.0;

  static AdminLayoutSize of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  static AdminLayoutSize fromWidth(double width) {
    if (width < compactMax) return AdminLayoutSize.compact;
    if (width <= mediumMax) return AdminLayoutSize.medium;
    return AdminLayoutSize.expanded;
  }
}
