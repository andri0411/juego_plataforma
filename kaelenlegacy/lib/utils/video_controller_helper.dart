import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Replaces [oldController] with the controller produced by [newControllerFuture].
///
/// This helper will try to remove the provided [onUpdate] listener from the
/// old controller, dispose the old controller safely, then await the new
/// controller and attach [onUpdate] to it. It centralizes the repetitive
/// try/catch/removeListener/dispose logic used across HomeScreen.
Future<VideoPlayerController> replaceController(
  VideoPlayerController? oldController,
  Future<VideoPlayerController> newControllerFuture, {
  VoidCallback? onUpdate,
}) async {
  try {
    if (oldController != null) {
      if (onUpdate != null) {
        try {
          oldController.removeListener(onUpdate);
        } catch (_) {}
      }
      try {
        await oldController.dispose();
      } catch (_) {}
    }
  } catch (_) {}

  final newController = await newControllerFuture;
  if (onUpdate != null) newController.addListener(onUpdate);
  return newController;
}
