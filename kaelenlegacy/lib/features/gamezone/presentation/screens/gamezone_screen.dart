import 'package:flutter/material.dart';
// Orientation changes are intentionally avoided for GameZone; we keep
// the helper available elsewhere but don't need it in this file.
import 'dart:typed_data';
import 'package:kaelenlegacy/utils/image_rotator.dart';

class GameZoneScreen extends StatefulWidget {
  final Uint8List? rotatedBackground;

  const GameZoneScreen({Key? key, this.rotatedBackground}) : super(key: key);

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen> {
  Uint8List? _rotatedImageBytes;
  bool _rotationRequested = false;

  @override
  void initState() {
    super.initState();
    // We intentionally avoid forcing device orientation here so the
    // OS does not animate a rotation. The UI will display a pre-rotated
    // background image so the screen appears horizontal immediately.

    // Use provided rotated bytes if passed; otherwise request a cached
    // rotated version. This will avoid repeated rotations and will
    // usually return immediately if prewarmed (see HomeScreen).
    if (widget.rotatedBackground != null) {
      _rotatedImageBytes = widget.rotatedBackground;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If the app is currently in portrait (unlikely when app is global
    // landscape), ensure we have a rotated background ready. If the app
    // is in landscape, we'll display the original asset directly.
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait && !_rotationRequested) {
      _rotationRequested = true;
      if (_rotatedImageBytes == null) {
        getRotatedAsset('assets/images/mapbackground.png')
            .then((bytes) {
              if (!mounted) return;
              setState(() {
                _rotatedImageBytes = bytes;
              });
            })
            .catchError((e) {
              debugPrint(
                '[GameZoneScreen] failed to load rotated background: $e',
              );
            });
      }
    }
  }

  @override
  void dispose() {
    // No orientation restore here because we did not change it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      body: SizedBox.expand(
        child: orientation == Orientation.landscape
            // App is landscape: show the original asset (no rotation needed)
            ? Image.asset(
                'assets/images/mapbackground.png',
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            // App is portrait: show the pre-rotated bytes if available
            : (_rotatedImageBytes == null
                  ? Container(color: Colors.black)
                  : Image.memory(
                      _rotatedImageBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )),
      ),
    );
  }
}
