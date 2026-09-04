import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class RbSectionLabel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const RbSectionLabel({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.headingSmall),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.saffron)),
            ),
        ],
      ),
    );
  }
}
