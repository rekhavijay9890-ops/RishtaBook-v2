import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RbAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color color;
  /// When set, shows this photo instead of the initials circle. Falls back
  /// to initials automatically if the image fails to load.
  final String? photoUrl;
  /// Visual-only privacy nudge for a profile owner with photosPrivate set,
  /// viewed by someone they haven't matched with yet. NOT a real access
  /// control - the image URL is still fetched and blurred client-side
  /// (this app has no backend to gate the actual bytes on). Good enough to
  /// discourage casual screenshotting/sharing, not a security boundary.
  final bool blurred;

  const RbAvatar({super.key, required this.initials, this.size = 44, this.color = AppColors.saffron, this.photoUrl, this.blurred = false});

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
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              (blurred
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null ? child : _initials(),
                        errorBuilder: (context, error, stack) => _initials(),
                      ),
                    )
                  : Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null ? child : _initials(),
                      errorBuilder: (context, error, stack) => _initials(),
                    ))
            else
              _initials(),
            if (hasPhoto && blurred)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: Icon(Icons.lock_outline, color: Colors.white, size: size * 0.35),
              ),
          ],
        ),
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
