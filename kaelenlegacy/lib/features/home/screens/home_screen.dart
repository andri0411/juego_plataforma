import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaelenlegacy/utils/orientation_helper.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _hasEnded = false;
  bool _isLooping = false;
  late final AnimationController _fadeController;
  bool _isFading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Note: Orientation is handled by `LandscapeOnly` wrapper.

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Start by playing the intro once; when it ends we'll switch to the
    // looping `airanima.mp4` animation.
    _playIntro();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _fadeController.dispose();
    // Orientation restored by `LandscapeOnly` dispose.
    super.dispose();
  }

  Future<void> _playIntro() async {
    // Ensure any existing controller is disposed first
    try {
      _controller.removeListener(_onVideoUpdate);
      await _controller.dispose();
    } catch (_) {}

    _isLooping = false;
    _hasEnded = false;

    _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
    await _controller.initialize();
    if (!mounted) return;
    setState(() {});
    _controller.setLooping(false);
    _controller.setVolume(1.0);
    _controller.play();
    _controller.addListener(_onVideoUpdate);
  }

  Future<void> _switchToLoopingAnimation() async {
    // Switch to the looping airanima animation. Dispose the old controller
    // and replace it with a looping one.
    _isLooping = true;

    try {
      _controller.removeListener(_onVideoUpdate);
      await _controller.dispose();
    } catch (_) {}

    _controller = VideoPlayerController.asset('assets/videos/airanima.mp4');
    await _controller.initialize();
    if (!mounted) return;
    setState(() {});
    _controller.setLooping(true);
    _controller.setVolume(1.0);
    _controller.play();
    // keep listener in case lifecycle events need to inspect state
    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (!_controller.value.isInitialized) return;
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (position >= duration && !_hasEnded) {
      _hasEnded = true;
      // If the intro finished and we haven't switched yet, start the looping
      // animation.
      if (!_isLooping) {
        _fadeToSwitch();
      }
    }
  }

  Future<void> _fadeToSwitch() async {
    if (_isFading) return;
    _isFading = true;

    try {
      // Fade to black
      await _fadeController.forward();

      // After screen is dark, switch the video
      await _switchToLoopingAnimation();

      // Fade back to reveal the looping animation
      await _fadeController.reverse();
    } finally {
      _isFading = false;
    }
  }

  // Quit the game by popping the platform navigator.
  // On Android this closes the activity; on iOS programmatic exits are discouraged.
  void _quitGame() {
    SystemNavigator.pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When app is resumed, always restart the intro sequence from start.
      // This disposes any current controller and begins the intro clip.
      _playIntro();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LandscapeOnly(
      child: Scaffold(
        body: Stack(
          children: [
            // Background video
            SizedBox.expand(
              child: _controller.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : Container(color: Colors.black),
            ),

            // Fade overlay used for transitions between intro and looping anim
            // AnimatedBuilder listens to the fade controller and paints a black
            // overlay with opacity.
            IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(_fadeController.value),
                  );
                },
              ),
            ),
            // Dark radial overlay in bottom-left corner (doesn't block interactions)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomLeft,
                      // radius slightly > 1 so the circle covers the corner fully
                      radius: 1.25,
                      colors: [
                        Colors.black.withOpacity(0.90),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp,
                    ),
                  ),
                ),
              ),
            ),

            // Top-left title + blurred menu (increased blur)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12.0,
                  left: 6.0,
                  right: 12.0,
                  bottom: 12.0,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title without background or blur — only text with shadows
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 14.0,
                        ),
                        child: Text(
                          'Kaelen Legacy',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 3),
                                blurRadius: 8.0,
                                color: Colors.black87,
                              ),
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4.0,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 34.0),

                      // Menu options under the title
                      Padding(
                        padding: const EdgeInsets.only(left: 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Game',
                              style: TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 22,
                                fontWeight: FontWeight.w500, // medium
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 6.0,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.0),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 6.0,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.0),
                            GestureDetector(
                              onTap: _quitGame,
                              child: Text(
                                'Quit game',
                                style: TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 6.0,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
