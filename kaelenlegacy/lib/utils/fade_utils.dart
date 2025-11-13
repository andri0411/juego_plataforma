import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Helper functions to control a full-screen fade overlay using an
/// [AnimationController].
///
/// These centralize the animations used across the home screen video
/// transitions so timing and easing are consistent.

/// Animate the overlay to full black (opacity = 1.0).
Future<void> darken(
  AnimationController controller, {
  Duration? duration,
  Curve curve = Curves.easeIn,
}) async {
  final d = duration ?? controller.duration ?? Duration(milliseconds: 900);
  await controller.animateTo(1.0, duration: d, curve: curve);
}

/// Animate the overlay down to transparent (opacity = 0.0).
Future<void> lighten(
  AnimationController controller, {
  Duration? duration,
  Curve curve = Curves.easeOut,
}) async {
  final d = duration ?? controller.duration ?? Duration(milliseconds: 200);
  await controller.animateTo(0.0, duration: d, curve: curve);
}

/// Start a pre-fade (non-await). Useful for kicking off the pre-fade a
/// short time before a clip ends.
void startPreFade(AnimationController controller) {
  // Fire-and-forget
  controller.forward();
}

/// Attach a listener to [controller] that will start a pre-fade on
/// [fadeController] when the video's remaining duration is less than or
/// equal to [preFadeDuration]. Returns a function to remove the listener.
VoidCallback watchPreFade(
  VideoPlayerController controller,
  AnimationController fadeController, {
  Duration preFadeDuration = const Duration(milliseconds: 900),
}) {
  void listener() {
    try {
      if (!controller.value.isInitialized) return;
      final position = controller.value.position;
      final duration = controller.value.duration;
      final remaining = duration - position;
      if (remaining <= preFadeDuration) {
        startPreFade(fadeController);
        // remove after triggered
        try {
          controller.removeListener(listener);
        } catch (_) {}
      }
    } catch (_) {}
  }

  controller.addListener(listener);
  return () {
    try {
      controller.removeListener(listener);
    } catch (_) {}
  };
}
