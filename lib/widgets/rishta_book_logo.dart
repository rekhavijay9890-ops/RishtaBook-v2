import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Matrimonial brand mark: two figures forming a heart within a maroon
/// medallion — used in auth, headers, and launcher assets.
class RishtaBookLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final bool showBorder;

  const RishtaBookLogo({
    super.key,
    this.size = 88,
    this.showShadow = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.accentGradient,
        border: showBorder
            ? Border.all(color: AppColors.brandGold.withOpacity(0.55), width: size * 0.035)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.11),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _MatrimonialLogoPainter(
          figureColor: Colors.white.withOpacity(0.95),
          heartColor: AppColors.brandGold,
        ),
      ),
    );
  }
}

class _MatrimonialLogoPainter extends CustomPainter {
  final Color figureColor;
  final Color heartColor;

  const _MatrimonialLogoPainter({
    required this.figureColor,
    required this.heartColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final figurePaint = Paint()
      ..color = figureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    // Left figure — head + curved shoulder
    canvas.drawCircle(Offset(cx - w * 0.17, cy - h * 0.12), w * 0.07, Paint()..color = figureColor);
    final leftBody = Path()
      ..moveTo(cx - w * 0.17, cy - h * 0.04)
      ..quadraticBezierTo(cx - w * 0.28, cy + h * 0.08, cx - w * 0.08, cy + h * 0.18);
    canvas.drawPath(leftBody, figurePaint);

    // Right figure — mirrored
    canvas.drawCircle(Offset(cx + w * 0.17, cy - h * 0.12), w * 0.07, Paint()..color = figureColor);
    final rightBody = Path()
      ..moveTo(cx + w * 0.17, cy - h * 0.04)
      ..quadraticBezierTo(cx + w * 0.28, cy + h * 0.08, cx + w * 0.08, cy + h * 0.18);
    canvas.drawPath(rightBody, figurePaint);

    // Connecting hands / bond arc
    final bond = Path()
      ..moveTo(cx - w * 0.08, cy + h * 0.18)
      ..quadraticBezierTo(cx, cy + h * 0.24, cx + w * 0.08, cy + h * 0.18);
    canvas.drawPath(bond, figurePaint..strokeWidth = w * 0.035);

    // Heart at center
    _drawHeart(canvas, Offset(cx, cy + h * 0.02), w * 0.11, heartColor);
  }

  void _drawHeart(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy + radius * 0.35);
    path.cubicTo(
      center.dx - radius * 1.2,
      center.dy - radius * 0.45,
      center.dx - radius * 0.35,
      center.dy - radius * 1.05,
      center.dx,
      center.dy - radius * 0.55,
    );
    path.cubicTo(
      center.dx + radius * 0.35,
      center.dy - radius * 1.05,
      center.dx + radius * 1.2,
      center.dy - radius * 0.45,
      center.dx,
      center.dy + radius * 0.35,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MatrimonialLogoPainter oldDelegate) =>
      oldDelegate.figureColor != figureColor || oldDelegate.heartColor != heartColor;
}
