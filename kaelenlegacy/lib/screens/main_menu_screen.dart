import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'menu_option.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  bool _isFadingOut = false;
  bool _isIntro = false;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeController);
    _controller = VideoPlayerController.asset('assets/videos/flame.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.play();
        });
        _fadeController.forward();
        _controller.addListener(_videoListener);
      });
  }

  void _videoListener() {
    if (!_isFadingOut && !_isIntro && _controller.value.isInitialized) {
      final duration = _controller.value.duration;
      final position = _controller.value.position;
      if (duration.inMilliseconds > 0 &&
          duration.inSeconds - position.inSeconds <= 1) {
        _isFadingOut = true;
        _fadeController.reverse().then((_) async {
          await _controller.pause();
          await _controller.dispose();
          _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
          await _controller.initialize();
          _controller.setLooping(true);
          setState(() {
            _isIntro = true;
            _isInitialized = true;
            _isFadingOut = false;
            _showTitle = false;
          });
          _controller.play();
          _fadeController.forward();
          Future.delayed(const Duration(milliseconds: 1000), () {
            setState(() {
              _showTitle = true;
            });
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized)
            Stack(
              children: [
                SizedBox.expand(child: VideoPlayer(_controller)),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                          Colors.black,
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(color: Colors.black),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(color: Colors.black),
              );
            },
          ),
          if (_showTitle)
            Positioned(
              right: 24,
              top: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kaelen',
                    style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 6,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 90),
                    child: Text(
                      'Legacy',
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontWeight: FontWeight.bold,
                        fontSize: 42,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 6,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'New Game',
                          style: const TextStyle(
                            fontFamily: 'Spectral',
                            fontStyle: FontStyle.italic,
                            fontSize: 28,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Settings',
                          style: const TextStyle(
                            fontFamily: 'Spectral',
                            fontStyle: FontStyle.italic,
                            fontSize: 28,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Quit',
                          style: const TextStyle(
                            fontFamily: 'Spectral',
                            fontStyle: FontStyle.italic,
                            fontSize: 28,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
