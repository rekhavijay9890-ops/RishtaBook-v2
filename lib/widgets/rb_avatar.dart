import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RbAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color color;

  const RbAvatar({super.key, required this.initials, this.size = 44, this.color = AppColors.saffron});

  Color get _bg {
    if (color == AppColors.saffron) return AppColors.safLight;
    if (color == AppColors.teal) return AppColors.tealLight;
    if (color == AppColors.gold) return AppColors.goldLight;
    if (color == AppColors.rose) return AppColors.roseLight;
    return const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bg,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(fontSize: size * 0.3, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
        ),
      ),
    );
  }
}
