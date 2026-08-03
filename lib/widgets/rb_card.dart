import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RbCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? background;

  const RbCard({super.key, required this.child, this.padding, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}
