import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The app's signature shape: a scalloped arch, borrowed from the
/// bordered edge of a wedding invitation card.
class ScallopClipper extends CustomClipper<Path> {
  final double scallopRadius;
  const ScallopClipper({this.scallopRadius = 14});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - scallopRadius);

    final scallopCount = (size.width / (scallopRadius * 2)).round().clamp(1, 1000);
    final actualScallopWidth = size.width / scallopCount;

    for (int i = 0; i < scallopCount; i++) {
      final startX = i * actualScallopWidth;
      path.arcToPoint(
        Offset(startX + actualScallopWidth, size.height - scallopRadius),
        radius: Radius.circular(actualScallopWidth / 2),
        clockwise: false,
      );
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A ready-to-use header band with the scalloped bottom edge, filled
/// with the primary gradient, holding [child] (title, logo, etc.).
class ScallopHeader extends StatelessWidget {
  final double height;
  final Widget child;

  const ScallopHeader({super.key, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const ScallopClipper(),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.only(bottom: 22),
        child: child,
      ),
    );
  }
}

/// A small ornamental divider - a nod to rangoli/kalash motifs, used in
/// place of a plain [Divider] wherever a section break wants warmth.
class OrnateDivider extends StatelessWidget {
  final double verticalPadding;
  const OrnateDivider({super.key, this.verticalPadding = 18});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(width: 7, height: 7, color: AppColors.accent),
            ),
          ),
          Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        ],
      ),
    );
  }
}
