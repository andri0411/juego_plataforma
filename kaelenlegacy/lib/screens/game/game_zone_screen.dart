import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GameZoneScreen extends StatefulWidget {
  final VoidCallback? onVideoEnd;
  const GameZoneScreen({Key? key, this.onVideoEnd}) : super(key: key);

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen> {
    bool _isShowMapVideo = false;
  late VideoPlayerController _controller;
  // ...existing code...

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/newgameintro.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(false);
        _controller.addListener(_videoListener);
      });
  }

  void _videoListener() {
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (duration.inMilliseconds > 0 && position >= duration) {
      // Cuando termina el primer video, reproducir el segundo
      _controller.removeListener(_videoListener);
      _controller.dispose();
      setState(() {
        _isShowMapVideo = true;
      });
      _controller = VideoPlayerController.asset('assets/videos/showmap.mp4')
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
          _controller.setLooping(false);
        });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          children: [
            Stack(
              children: [
                _controller.value.isInitialized
                    ? SizedBox.expand(child: VideoPlayer(_controller))
                    : Container(
                        color: Colors.black,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                if (_isShowMapVideo)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Image.asset(
                          'assets/images/door.png',
                          fit: BoxFit.contain,
                          width: 300,
                          height: 300,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // ...existing code...
          ],
        ),
      ),
    );
  }
}
