import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Returns a fully initialized [VideoPlayerController] for the new-game intro.
Future<VideoPlayerController> createNewGameIntroController({
  bool looping = false,
  double volume = 1.0,
  bool play = false,
  VoidCallback? onUpdate,
}) async {
  final controller = VideoPlayerController.asset(
    'assets/videos/newgameintro.mp4',
  );
  await controller.initialize();
  await controller.setLooping(looping);
  await controller.setVolume(volume);
  if (onUpdate != null) controller.addListener(onUpdate);
  if (play) controller.play();
  return controller;
}
