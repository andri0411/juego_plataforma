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
  bool _showDoor = false;
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
            Stack(
              children: [
                _controller.value.isInitialized
                    ? SizedBox.expand(child: VideoPlayer(_controller))
                    : Container(
                        color: Colors.black,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                if (_showDoor) ...[
                  Positioned(
                    left: 150, // distancia desde el borde izquierdo
                    top: 30, // distancia desde el borde superior
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/door.png',
                        fit: BoxFit.contain,
                        width: 140, // ancho en píxeles
                        height: 200, // alto en píxeles
                      ),
                    ),
                  ),
                  Positioned(
                    left: 420, // segunda imagen, más a la derecha
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
                    left: 700, // tercera imagen
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
                    left: 285, // cuarta imagen, más abajo
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
                    left: 560, // quinta imagen, más abajo y derecha
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
                ],
              ],
            ),
            // Texto 'exit' en la esquina inferior derecha solo cuando termina el video
            if (_showDoor)
              Positioned(
                right: 24, // distancia desde el borde derecho
                bottom: 24, // distancia desde el borde inferior
                child: Text(
                  'exit',
                  style: TextStyle(
                    fontFamily: 'Spectral', // nombre declarado en pubspec.yaml
                    fontWeight: FontWeight.w300, // Ligera
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
          ],
        ),
      ),
    );
  }
}
