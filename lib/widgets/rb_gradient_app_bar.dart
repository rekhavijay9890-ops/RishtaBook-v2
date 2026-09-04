import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Top bar with the shared brand gradient — use on pushed screens so
/// Complete Profile, Wallet sub-pages, etc. match Home/Search/Profile.
class RbGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  const RbGradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
      ),
    );
  }
}
