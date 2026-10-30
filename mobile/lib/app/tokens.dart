import 'package:flutter/widgets.dart';

/// The 8-point grid. Every margin, padding, gap and size in the app is one of these, or a half
/// step (4) for tight text pairs. Screens never write their own numbers (`test/grid_test.dart`
/// fails on a raw one). Rules: docs/03-standards/ui-ux-rules.md.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;

  /// Room under a list so the floating button never covers the last row (12 x 8).
  static const double fabClearance = 96;

  /// The side margin of every screen.
  static const double gutter = md;

  /// Smallest tap target (6 x 8).
  static const double tapTarget = xxxl;

  static const EdgeInsets page = EdgeInsets.all(md);
  static const EdgeInsets pageWithFab = EdgeInsets.fromLTRB(md, md, md, fabClearance);
  static const EdgeInsets card = EdgeInsets.all(md);
  static const EdgeInsets horizontal = EdgeInsets.symmetric(horizontal: md);
}

/// Corner radii, also on the grid.
abstract final class Corner {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.all(Radius.circular(lg));
}

/// Fixed gaps, so a column reads `Gap.md` instead of `SizedBox(height: 16)`.
abstract final class Gap {
  static const Widget xs = SizedBox.square(dimension: Space.xs);
  static const Widget sm = SizedBox.square(dimension: Space.sm);
  static const Widget md = SizedBox.square(dimension: Space.md);
  static const Widget lg = SizedBox.square(dimension: Space.lg);
  static const Widget xl = SizedBox.square(dimension: Space.xl);
}

/// Widest a column of content gets on a tablet or in a browser. Phones are narrower, so it changes nothing there.
const double maxContentWidth = 600;
