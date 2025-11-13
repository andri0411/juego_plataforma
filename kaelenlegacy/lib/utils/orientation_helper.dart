import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sets the preferred device orientations to landscape only.
Future<void> setLandscapeOnly() async {
  debugPrint('[orientation] setLandscapeOnly() called');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// Restores the preferred device orientation to portrait up.
Future<void> setPortraitUp() async {
  debugPrint('[orientation] setPortraitUp() called');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

/// A widget that ensures its subtree runs only in landscape mode.
///
/// Usage:
/// ```dart
/// return LandscapeOnly(
///   child: Scaffold(...),
/// );
/// ```
class LandscapeOnly extends StatefulWidget {
  final Widget child;

  const LandscapeOnly({Key? key, required this.child}) : super(key: key);

  @override
  State<LandscapeOnly> createState() => _LandscapeOnlyState();
}

class _LandscapeOnlyState extends State<LandscapeOnly> {
  @override
  void initState() {
    super.initState();
    // Set landscape when this widget is inserted in the tree
    debugPrint('[LandscapeOnly] initState -> setLandscapeOnly()');
    setLandscapeOnly();
  }

  @override
  void dispose() {
    // Restore portrait when leaving. Delay the restore briefly so that if
    // a new route is being pushed (which may itself request landscape), the
    // new route has a chance to re-apply its preferred orientation before
    // we restore portrait. This avoids a race where dispose() from the
    // previous route forces portrait while the new route is appearing.
    debugPrint('[LandscapeOnly] dispose -> delayed setPortraitUp()');
    Future.delayed(const Duration(milliseconds: 200), () {
      debugPrint('[LandscapeOnly] delayed dispose callback -> setPortraitUp()');
      setPortraitUp();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
