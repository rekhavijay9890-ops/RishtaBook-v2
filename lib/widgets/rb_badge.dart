import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RbBadge extends StatelessWidget {
  final String text;
  final Color color;

  const RbBadge({super.key, required this.text, this.color = AppColors.saffron});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
