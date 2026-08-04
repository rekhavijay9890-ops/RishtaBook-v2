import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RbAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color color;
  /// When set, shows this photo instead of the initials circle. Falls back
  /// to initials automatically if the image fails to load.
  final String? photoUrl;

  const RbAvatar({super.key, required this.initials, this.size = 44, this.color = AppColors.saffron, this.photoUrl});

  Color get _bg {
    if (color == AppColors.saffron) return AppColors.safLight;
    if (color == AppColors.teal) return AppColors.tealLight;
    if (color == AppColors.gold) return AppColors.goldLight;
    if (color == AppColors.rose) return AppColors.roseLight;
    return const Color(0xFFEEEEEE);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bg,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : _initials(),
                errorBuilder: (context, error, stack) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        initials,
        style: TextStyle(fontSize: size * 0.3, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
      ),
    );
  }
}
