import 'package:flutter/material.dart';

/// Standard layout breakpoints and responsive constraints for the application.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Standard Material Design 3 breakpoint for phones (< 600 dp).
  static const double compact = 600;

  /// Standard Material Design 3 breakpoint for tablets / landscape (600 - 840 dp).
  static const double medium = 840;

  /// Large tablets, desktop, expanded screens (>= 1200 dp).
  static const double expanded = 1200;

  /// Cutoff for small/narrow phones (e.g. 320 - 360 dp).
  static const double narrowPhone = 360;

  /// Max width for reading/form cards on tablets to prevent extreme stretching.
  static const double maxContentWidth = 760;

  /// Max width for forms and input screens.
  static const double maxFormWidth = 640;

  /// Max width for dialogs on tablets.
  static const double maxDialogWidth = 520;
}

/// Convenience extensions on [BuildContext] for responsive layout decisions.
extension ResponsiveContext on BuildContext {
  /// The current screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// The current screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// True if the current device width is less than 600 dp (compact phone).
  bool get isCompact => screenWidth < ResponsiveBreakpoints.compact;

  /// True if the current device is a very narrow phone (less than 360 dp).
  bool get isNarrowPhone => screenWidth < ResponsiveBreakpoints.narrowPhone;

  /// True if medium width (600 - 840 dp: large phone landscape, small tablet).
  bool get isMedium =>
      screenWidth >= ResponsiveBreakpoints.compact &&
      screenWidth < ResponsiveBreakpoints.medium;

  /// True if expanded width (>= 840 dp: tablet or desktop).
  bool get isExpanded => screenWidth >= ResponsiveBreakpoints.medium;

  /// Current text scale factor for accessibility scaling checks.
  double get textScaleFactor => MediaQuery.textScalerOf(this).scale(1.0);

  /// True if accessibility font scaling is enlarged (>= 1.25x).
  bool get isLargeFont => textScaleFactor >= 1.25;
}
