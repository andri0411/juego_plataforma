import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:kaelenlegacy/screens/home/main_menu_screen.dart'
    show SplashScreen;

class GameZoneScreen extends StatefulWidget {
  final VoidCallback? onVideoEnd;
  const GameZoneScreen({Key? key, this.onVideoEnd}) : super(key: key);

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen> {
  bool _isShowMapVideo = false;
  bool _showDoor = false;
  late VideoPlayerController _controller;

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
    if (!_isShowMapVideo &&
        duration.inMilliseconds > 0 &&
        position >= duration) {
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
          _controller.addListener(_videoListener);
        });
    } else if (_isShowMapVideo &&
        duration.inMilliseconds > 0 &&
        position >= duration) {
      // Cuando termina showmap.mp4, mostrar la puerta
      setState(() {
        _showDoor = true;
      });
      _controller.removeListener(_videoListener);
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
            _controller.value.isInitialized
                ? SizedBox.expand(child: VideoPlayer(_controller))
                : Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                  ),
            if (_showDoor) ...[
              // Todas las imágenes y el botón 'exit'
              Positioned(
                left: 150,
                top: 30,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/door.png',
                    fit: BoxFit.contain,
                    width: 140,
                    height: 200,
                  ),
                ),
              ),
              Positioned(
                left: 420,
                top: 30,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/door.png',
                    fit: BoxFit.contain,
                    width: 140,
                    height: 200,
                  ),
                ),
              ),
              Positioned(
                left: 700,
                top: 30,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/door.png',
                    fit: BoxFit.contain,
                    width: 140,
                    height: 200,
                  ),
                ),
              ),
              Positioned(
                left: 285,
                top: 250,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/door.png',
                    fit: BoxFit.contain,
                    width: 140,
                    height: 200,
                  ),
                ),
              ),
              Positioned(
                left: 560,
                top: 250,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/door.png',
                    fit: BoxFit.contain,
                    width: 140,
                    height: 200,
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: 24,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => SplashScreen()),
                    );
                  },
                  child: Text(
                    'exit',
                    style: TextStyle(
                      fontFamily: 'Spectral',
                      fontWeight: FontWeight.w300,
                      fontSize: 38,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(2, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
