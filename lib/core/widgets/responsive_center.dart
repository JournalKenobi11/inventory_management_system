import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';

/// Wraps content in a centered [ConstrainedBox] on wider screens (tablets, desktops)
/// while filling 100% of the width on phones, preserving ergonomics and design.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool useSafeArea;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.padding,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}
