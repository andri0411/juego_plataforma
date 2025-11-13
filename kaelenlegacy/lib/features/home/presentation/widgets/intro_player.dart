import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Returns a fully initialized [VideoPlayerController] for the main looping intro.
Future<VideoPlayerController> createIntroController({
  bool looping = true,
  double volume = 1.0,
  bool play = false,
  VoidCallback? onUpdate,
}) async {
  final controller = VideoPlayerController.asset('assets/videos/intro.mp4');
  await controller.initialize();
  await controller.setLooping(looping);
  await controller.setVolume(volume);
  if (onUpdate != null) controller.addListener(onUpdate);
  if (play) controller.play();
  return controller;
}
