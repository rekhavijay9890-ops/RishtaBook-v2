import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';

/// Autoplaying, looped, muted, inline video background with a warm/dark
/// overlay for text contrast. Falls back to the plain saffron gradient
/// (no crash, no blank screen) if the video fails to load or the device
/// blocks autoplay - e.g. low-power mode.
class VideoBackground extends StatefulWidget {
  final String asset;
  final Widget child;
  const VideoBackground({super.key, required this.asset, required this.child});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.asset(widget.asset);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) {
        setState(() => _controller = controller);
      } else {
        controller.dispose();
      }
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final ready = !_failed && ctrl != null && ctrl.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: ctrl.value.size.width,
              height: ctrl.value.size.height,
              child: VideoPlayer(ctrl),
            ),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.safDark, AppColors.saffron], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
        // Warm/dark overlay so white text and the sign-in card stay readable
        // over whatever the video happens to show at any given frame.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.45), AppColors.headerBg.withOpacity(0.72)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
