import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:kaelenlegacy/screens/home/home_screen.dart' show SplashScreen;

class GameZoneScreen extends StatefulWidget {
  final VoidCallback? onVideoEnd;
  const GameZoneScreen({Key? key, this.onVideoEnd}) : super(key: key);

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen> {
  double _fadeOpacity = 0.0; // Empieza transparente
  // ...existing code...
  late VideoPlayerController _controller;
  late VoidCallback _videoListener;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/newgameintro.mp4');
    _controller.initialize().then((_) {
      setState(() {});
    });
    _videoListener = () async {
      final position = _controller.value.position;
      duration = _controller.value.duration;
      if (duration.inMilliseconds > 0 && position >= duration) {
        _controller.removeListener(_videoListener);
        await _controller.pause();
      }
    };
    _controller.addListener(_videoListener);
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
      backgroundColor: Colors.black, // Evita pantallazo blanco
      body: Center(
        child: Stack(
          children: [
            _controller.value.isInitialized
                ? SizedBox.expand(child: VideoPlayer(_controller))
                : Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                  ),
            // Overlay negro para fade-out
            AnimatedOpacity(
              opacity: _fadeOpacity,
              duration: const Duration(milliseconds: 700),
              child: (_fadeOpacity > 0)
                  ? Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
