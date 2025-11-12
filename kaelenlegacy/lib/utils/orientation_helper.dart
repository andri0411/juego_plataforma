import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sets the preferred device orientations to landscape only.
Future<void> setLandscapeOnly() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

/// Restores the preferred device orientation to portrait up.
Future<void> setPortraitUp() async {
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
    setLandscapeOnly();
  }

  @override
  void dispose() {
    // Restore portrait when leaving
    setPortraitUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
