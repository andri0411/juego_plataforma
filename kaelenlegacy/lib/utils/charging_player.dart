import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';
import 'package:video_player/video_player.dart';
import 'package:kaelenlegacy/utils/fade_utils.dart';

/// Returns a fully initialized [VideoPlayerController] for the charging clip.
///
/// Optional parameters allow callers to control looping, initial volume,
/// start playing immediately, and attach an update listener.
Future<VideoPlayerController> createChargingController({
  bool looping = false,
  double volume = 1.0,
  bool play = false,
  Duration startDelay = const Duration(seconds: 1),
  AnimationController? fadeController,
  VoidCallback? onUpdate,
}) async {
  final controller = VideoPlayerController.asset('assets/videos/charching.mp4');
  await controller.initialize();
  await controller.setLooping(looping);
  await controller.setVolume(volume);
  if (onUpdate != null) controller.addListener(onUpdate);
  if (play) {
    // If a fade controller is provided, perform a brief darken before
    // starting playback so the transition into the charging clip is
    // smoother. This is non-blocking with respect to initialization but
    // we await the darken so the visual sequence is deterministic.
    if (fadeController != null) {
      try {
        await darken(
          fadeController,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } catch (_) {}
    }

    if (startDelay > Duration.zero) {
      await Future.delayed(startDelay);
    }

    controller.play();
  }
  return controller;
}
