import 'package:flutter/material.dart';
import '../theme/app_text.dart';

/// Dark top header used on every screen — optional back button, title,
/// trailing actions, and an optional `bottom` slot for a search bar or tabs.
class RbHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? bottom;
  final Widget? leading;

  const RbHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    this.bottom,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5E88), Color(0xFF7C4DBF), Color(0xFFC1447F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      ),
                    ),
                  if (leading != null) leading!,
                  Expanded(child: Text(title, style: AppText.headerTitle)),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
