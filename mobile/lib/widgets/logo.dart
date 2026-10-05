import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The DoseBook mark: an open book with a capsule above it.
/// Same geometry (108 x 108 grid) as the Android icon in
/// `android/app/src/main/res/drawable/ic_logo_foreground.xml` and the logo in the Figma file.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.badge = false});

  final double size;

  /// Draws the mark on a rounded square in the brand colour, like the launcher icon.
  /// Without it the mark is drawn alone, for use on a brand-coloured background.
  /// The colours are the brand's and do not change with light or dark mode.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = brandScheme;
    return Semantics(
      label: 'DoseBook logo',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(
          mark: scheme.onPrimary,
          accent: scheme.primaryContainer,
          background: badge ? scheme.primary : null,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.mark, required this.accent, this.background});

  final Color mark;
  final Color accent;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108);
    if (background != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 108, 108), const Radius.circular(24)),
        Paint()..color = background!,
      );
    }
    // Keeps the drawing inside the centre two thirds, the part Android never crops.
    canvas.translate(0, 4);
    canvas.translate(54, 50);
    canvas.scale(0.88);
    canvas.translate(-54, -50);

    final fill = Paint()..color = mark;
    // A round-joined outline in the same colour softens the corners of the pages.
    final edge = Paint()
      ..color = mark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final leftPage = Path()
      ..moveTo(30, 44)
      ..lineTo(52, 50)
      ..lineTo(52, 80)
      ..lineTo(30, 74)
      ..close();
    final rightPage = Path()
      ..moveTo(78, 44)
      ..lineTo(56, 50)
      ..lineTo(56, 80)
      ..lineTo(78, 74)
      ..close();
    for (final page in [leftPage, rightPage]) {
      canvas.drawPath(page, fill);
      canvas.drawPath(page, edge);
    }

    // The capsule: two halves, tilted, above the fold of the book.
    canvas.translate(54, 31);
    canvas.rotate(-35 * math.pi / 180);
    final leftHalf = Path()
      ..moveTo(0, -5.5)
      ..lineTo(-7.5, -5.5)
      ..arcToPoint(const Offset(-7.5, 5.5), radius: const Radius.circular(5.5), clockwise: false)
      ..lineTo(0, 5.5)
      ..close();
    final rightHalf = Path()
      ..moveTo(0, -5.5)
      ..lineTo(7.5, -5.5)
      ..arcToPoint(const Offset(7.5, 5.5), radius: const Radius.circular(5.5))
      ..lineTo(0, 5.5)
      ..close();
    canvas.drawPath(leftHalf, fill);
    canvas.drawPath(rightHalf, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.mark != mark || old.accent != accent || old.background != background;
}
