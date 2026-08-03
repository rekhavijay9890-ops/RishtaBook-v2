import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RbPillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? textColor;
  final bool outline;

  const RbPillButton({super.key, required this.text, this.onTap, this.bg, this.textColor, this.outline = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : (bg ?? AppColors.saffron),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: outline ? AppColors.saffron : Colors.transparent, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: outline ? AppColors.saffron : (textColor ?? Colors.white)),
        ),
      ),
    );
  }
}
