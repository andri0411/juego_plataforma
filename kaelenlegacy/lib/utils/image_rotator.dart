import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

/// Internal helper that rotates the given image bytes 90° clockwise.
Future<Uint8List> _rotateBytes90Clockwise(Uint8List bytes) async {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, (ui.Image img) {
    completer.complete(img);
  });
  final ui.Image original = await completer.future;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  // Translate by the original height and rotate 90deg clockwise.
  canvas.translate(original.height.toDouble(), 0);
  canvas.rotate(math.pi / 2);
  final paint = ui.Paint();
  canvas.drawImage(original, ui.Offset.zero, paint);

  final picture = recorder.endRecording();
  final ui.Image rotated = await picture.toImage(
    original.height,
    original.width,
  );
  final byteData = await rotated.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('Failed to convert rotated image to bytes');
  }
  return byteData.buffer.asUint8List();
}

// Simple in-memory cache to avoid re-rotating repeatedly.
final Map<String, Uint8List> _rotatedCache = {};

/// Rotate an asset image 90° clockwise and return PNG bytes. Results are
/// cached in-memory and subsequent calls return the cached bytes.
Future<Uint8List> getRotatedAsset(String assetPath) async {
  if (_rotatedCache.containsKey(assetPath)) return _rotatedCache[assetPath]!;
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List();
  final rotated = await _rotateBytes90Clockwise(bytes);
  _rotatedCache[assetPath] = rotated;
  return rotated;
}

/// Return the cached rotated bytes if available, otherwise `null`.
Uint8List? getRotatedAssetCached(String assetPath) => _rotatedCache[assetPath];

/// Convenience alias kept for compatibility.
Future<Uint8List> rotateAsset90Clockwise(String assetPath) =>
    getRotatedAsset(assetPath);
