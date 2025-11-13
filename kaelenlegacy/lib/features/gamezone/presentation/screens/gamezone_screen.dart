import 'package:flutter/material.dart';
import 'package:kaelenlegacy/utils/orientation_helper.dart';

class GameZoneScreen extends StatefulWidget {
  const GameZoneScreen({Key? key}) : super(key: key);

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen> {
  @override
  void initState() {
    super.initState();
    // Force landscape when this screen is shown.
    debugPrint('[GameZoneScreen] initState -> setLandscapeOnly()');
    setLandscapeOnly();
    // Re-apply after the first frame and briefly after to ensure the
    // orientation override takes effect even if the previous route's
    // dispose() restores portrait during the transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[GameZoneScreen] postFrame -> reapplying setLandscapeOnly()');
      setLandscapeOnly();
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      debugPrint(
        '[GameZoneScreen] delayed 120ms -> reapplying setLandscapeOnly()',
      );
      setLandscapeOnly();
    });
  }

  @override
  void dispose() {
    debugPrint('[GameZoneScreen] dispose -> setPortraitUp()');
    // Restore portrait when leaving the screen.
    setPortraitUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: RotatedBox(
          // Rotate the background image 90 degrees so it appears
          // horizontal (use quarterTurns: 1 for 90° clockwise).
          quarterTurns: 1,
          child: SizedBox.expand(
            child: Image.asset(
              'assets/images/mapbackground.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
