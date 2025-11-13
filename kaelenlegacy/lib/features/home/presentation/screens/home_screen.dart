import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaelenlegacy/utils/orientation_helper.dart';
import 'package:kaelenlegacy/utils/charging_player.dart';
import 'package:kaelenlegacy/features/home/presentation/widgets/intro_player.dart';
import 'package:kaelenlegacy/features/home/presentation/widgets/newgameintro_player.dart';
import 'package:kaelenlegacy/utils/video_controller_helper.dart';
import 'package:kaelenlegacy/features/home/presentation/widgets/home_menu.dart';
import 'package:kaelenlegacy/features/gamezone/presentation/screens/gamezone_screen.dart';
import 'package:kaelenlegacy/utils/fade_utils.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _hasEnded = false;
  bool _showTexts = false;
  bool _isLooping = false;
  bool _playedCharging = false;
  bool _playingCharging = false;
  bool _playingNewGameIntro = false;
  bool _sequenceAfterNewGame = false;
  bool _chargingForNewGame = false;
  late final AnimationController _fadeController;
  bool _hasStartedPreFade = false;
  bool _isFading = false;
  final Duration _preFadeDuration = Duration(milliseconds: 900);
  final Duration _slowRevealDuration = Duration(milliseconds: 600);
  final Duration _quickRevealDuration = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Note: Orientation is handled by `LandscapeOnly` wrapper.

    // Create fade controller for the charging->intro transition
    _fadeController = AnimationController(
      vsync: this,
      duration: _preFadeDuration,
    );

    // Start with the screen fully dark so the app doesn't appear abruptly.
    // The charging controller itself will delay playback (default 2s), so
    // we can call _playCharging() immediately and it will start playing
    // after that delay while keeping the overlay until we reveal it.
    _fadeController.value = 1.0;
    _playCharging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller != null) {
      try {
        _controller!.removeListener(_onVideoUpdate);
      } catch (_) {}
      _controller!.dispose();
    }
    _fadeController.dispose();
    // Orientation restored by `LandscapeOnly` dispose.
    super.dispose();
  }

  Future<void> _playCharging() async {
    // Play the charging/loading video once, then we'll switch to looping intro.
    _playedCharging = true;
    _playingCharging = true;

    try {
      _controller = await replaceController(
        _controller,
        createChargingController(looping: false, volume: 1.0, play: true),
        onUpdate: _onVideoUpdate,
      );
      // Ensure pre-fade is watched so the overlay begins before the clip ends
      if (_controller != null) {
        watchPreFade(
          _controller!,
          _fadeController,
          preFadeDuration: _preFadeDuration,
        );
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {});
    // Reveal the screen when this clip starts
    // Use the slower reveal for the charging clip so the transition from
    // dark -> clear feels less abrupt.
    await lighten(
      _fadeController,
      duration: _slowRevealDuration,
      curve: Curves.easeOut,
    );
  }

  Future<void> _startLoopingIntro() async {
    // Start intro.mp4 in looping mode and show the UI texts.
    // Prevent re-entrance
    if (_isFading) return;
    _isFading = true;

    // We'll run a small transition: if a pre-fade started, ensure it's
    // completed (screen is black) before switching. Then reveal in two
    // stages: slow then quick while intro loops.
    _isLooping = true;

    try {
      if (_hasStartedPreFade) {
        // wait for pre-fade to finish
        await darken(_fadeController);
      } else {
        // If no pre-fade, perform a quick fade to black for consistency
        await darken(_fadeController);
      }

      try {
        _controller = await replaceController(
          _controller,
          createIntroController(looping: true, volume: 1.0, play: true),
          onUpdate: _onVideoUpdate,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {});

      // Reveal in two stages: slow to partial, then quick to full
      await _fadeController.animateTo(
        0.4,
        duration: _slowRevealDuration,
        curve: Curves.easeInOut,
      );
      await lighten(
        _fadeController,
        duration: _quickRevealDuration,
        curve: Curves.easeOut,
      );

      // Reveal texts now that the looping intro is playing
      _showTexts = true;
      if (mounted) setState(() {});

      // Reset pre-fade state
      _hasStartedPreFade = false;
      _playingCharging = false;
    } finally {
      _isFading = false;
    }
  }

  Future<void> _playNewGameIntro() async {
    // Prevent re-entrance
    if (_isFading) return;
    _isFading = true;

    // Hide UI texts immediately
    _showTexts = false;
    if (mounted) setState(() {});

    // Ensure we reset ended state so the listener can work correctly
    _hasEnded = false;
    _isLooping = false;
    // Mark that we're playing the new-game intro and that a sequence should
    // follow (charging -> enter gamezone).
    _playingNewGameIntro = true;
    _sequenceAfterNewGame = true;

    // Fast fade to black (use centralized helper)
    await darken(
      _fadeController,
      duration: Duration(milliseconds: 250),
      curve: Curves.easeIn,
    );

    // Switch to newgameintro.mp4
    try {
      _controller = await replaceController(
        _controller,
        createNewGameIntroController(looping: false, volume: 1.0, play: true),
        onUpdate: _onVideoUpdate,
      );
      if (_controller != null) {
        watchPreFade(
          _controller!,
          _fadeController,
          preFadeDuration: _preFadeDuration,
        );
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {});

    // Quick reveal
    await lighten(
      _fadeController,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    _isFading = false;
  }

  Future<void> _playChargingForNewGame() async {
    // Play the charging/loading video once as part of the new-game flow.
    _chargingForNewGame = true;
    _playedCharging = true;

    // Ensure end flag is reset so listener works for the charging clip
    _hasEnded = false;

    try {
      _controller = await replaceController(
        _controller,
        createChargingController(looping: false, volume: 1.0, play: true),
        onUpdate: _onVideoUpdate,
      );
      if (_controller != null) {
        watchPreFade(
          _controller!,
          _fadeController,
          preFadeDuration: _preFadeDuration,
        );
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {});

    // Optionally reveal quickly if needed
    await lighten(
      _fadeController,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _onVideoUpdate() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    final remaining = duration - position;

    // If the new-game intro is playing and it ends, start the charging clip
    // that is part of the new-game flow.
    if (_playingNewGameIntro && position >= duration && !_hasEnded) {
      _hasEnded = true;
      _playingNewGameIntro = false;
      if (_sequenceAfterNewGame) {
        _sequenceAfterNewGame = false;
        _playChargingForNewGame();
        return;
      }
    }

    // If charging played as part of the new-game flow and it ended, navigate
    // to the GameZone screen.
    if (_chargingForNewGame && position >= duration && !_hasEnded) {
      _hasEnded = true;
      _chargingForNewGame = false;
      // Navigate to gamezone and replace this screen.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                // Import here to avoid cycles; the file is in gamezone feature
                // and simple to reference.
                // We'll import at the top of the file.
                GameZoneScreen(),
          ),
        );
      }
      return;
    }

    // If we're playing the charging clip, start pre-fade shortly before it ends
    if (_playingCharging &&
        !_hasStartedPreFade &&
        remaining <= _preFadeDuration) {
      _hasStartedPreFade = true;
      // start pre-fade (do not await)
      startPreFade(_fadeController);
    }

    if (position >= duration && !_hasEnded) {
      _hasEnded = true;

      // Decide next step based on current stage:
      // - If we haven't played the charging clip yet, play it.
      // - Else if we're not looping yet, start looping intro.
      // - Otherwise, do nothing.
      if (!_playedCharging && !_isLooping) {
        _playCharging();
      } else if (!_isLooping) {
        _startLoopingIntro();
      }
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
    // When the app is paused/inactive, pause playback but keep the
    // controller so we can resume where we left off.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        _controller?.pause();
      } catch (_) {}
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // If we still have an initialized controller, just resume playback
      // instead of restarting the whole intro sequence.
      if (_controller != null && _controller!.value.isInitialized) {
        try {
          _controller!.play();
        } catch (_) {}
      } else {
        // Fallback: if there's no controller, start the charging intro.
        _playCharging();
      }
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
              child: (_controller != null && _controller!.value.isInitialized)
                  ? FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  : Container(color: Colors.black),
            ),

            // Full-screen fade overlay controlled by _fadeController. Covers the
            // entire screen so the darkening is visible during the transition
            // from `charching.mp4` to the looping `intro.mp4`.
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
                      // radius controls how far the dark corner reaches
                      // increased to make the dark corner cover more area
                      radius: 2.0,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp,
                    ),
                  ),
                ),
              ),
            ),

            // Top-left title + menu encapsulated into HomeMenu widget
            HomeMenu(
              show: _showTexts,
              onNewGame: _playNewGameIntro,
              onSettings: () {},
              onQuit: _quitGame,
            ),
          ],
        ),
      ),
    );
  }
}
