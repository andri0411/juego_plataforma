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
                // Mostrar la ruleta de opciones vertical y pegada a la derecha
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.18,
                  right: 0,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: 120,
                    child: MenuCarousel(vertical: true),
                  ),
                ),
              ],
            )
          else if (_showTitle) ...[
            // Título centrado arriba
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Kaelen',
                    textAlign: TextAlign.center,
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
                  Text(
                    'Legacy',
                    textAlign: TextAlign.center,
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
                ],
              ),
            ),
            // Ruleta de opciones vertical y pegada a la derecha
            Positioned(
              top: MediaQuery.of(context).size.height * 0.18,
              right: 0,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: 120,
                child: MenuCarousel(vertical: true),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget para la ruleta de opciones
class MenuCarousel extends StatefulWidget {
  final bool vertical;
  const MenuCarousel({this.vertical = false, Key? key}) : super(key: key);

  @override
  State<MenuCarousel> createState() => _MenuCarouselState();
}

class _MenuCarouselState extends State<MenuCarousel> {
  late final PageController _pageController;
  final List<String> options = ['New Game', 'Settings', 'Quit'];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vertical) {
      return RotatedBox(
        quarterTurns: 1,
        child: PageView.builder(
          scrollDirection: Axis.horizontal,
          controller: _pageController,
          itemCount: options.length,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final isSelected = index == _selectedIndex;
            return Center(
              child: RotatedBox(
                quarterTurns: -1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(vertical: isSelected ? 16 : 8),
                  child: Text(
                    options[index],
                    style: TextStyle(
                      fontFamily: 'Spectral',
                      fontStyle: FontStyle.italic,
                      fontSize: isSelected ? 36 : 28,
                      color: isSelected ? Colors.white : Colors.white54,
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
              ),
            );
          },
        ),
      );
    } else {
      return PageView.builder(
        controller: _pageController,
        itemCount: options.length,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final isSelected = index == _selectedIndex;
          return Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8),
              child: Text(
                options[index],
                style: TextStyle(
                  fontFamily: 'Spectral',
                  fontStyle: FontStyle.italic,
                  fontSize: isSelected ? 36 : 28,
                  color: isSelected ? Colors.white : Colors.white54,
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
          );
        },
      );
    }
  }
}
