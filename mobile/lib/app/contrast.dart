import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2.x contrast ratio between two opaque colours, 1 to 21.
double contrastRatio(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) => 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

/// The nearest shade of [fg] that reaches [minRatio] against [bg]: darker on a light background,
/// lighter on a dark one. Keeps the hue; used to lift a generated role over the AAA line (7:1).
Color ensureContrast(Color fg, Color bg, {double minRatio = 7.0}) {
  if (contrastRatio(fg, bg) >= minRatio) return fg;
  final towards = _luminance(bg) > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  for (var t = 0.02; t < 1.0; t += 0.02) {
    final c = Color.lerp(fg, towards, t)!;
    if (contrastRatio(c, bg) >= minRatio) return c;
  }
  return towards;
}
