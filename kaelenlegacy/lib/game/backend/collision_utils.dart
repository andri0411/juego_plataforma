import 'dart:typed_data';
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'obstacles/spikes.dart';

/// Pixel-perfect collision between a player area and a spike.
///
/// If `playerMask` and `playerNaturalSize` are provided, both the player's
/// alpha mask and the spike's alpha mask are checked — collision only
/// registers when both pixels are opaque at the same world point.
/// If `playerMask` is null, falls back to checking only the spike mask
/// (legacy behaviour).
bool checkPixelPerfectCollision(
  Rect playerRect,
  Spike spike, {
  Uint8List? playerMask,
  Vector2? playerNaturalSize,
}) {
  final spikeRect = Rect.fromLTWH(
    spike.position.x - spike.size.x / 2,
    spike.position.y - spike.size.y,
    spike.size.x,
    spike.size.y,
  );
  if (!playerRect.overlaps(spikeRect)) return false;

  final overlap = playerRect.intersect(spikeRect);
  if (overlap.width <= 0 || overlap.height <= 0) return false;

  final int spikeImgW = spike.naturalSize.x.toInt();
  final int spikeImgH = spike.naturalSize.y.toInt();
  final Uint8List spikeMask = spike.alphaMask;

  final double spikeLeft = spike.position.x - spike.size.x / 2;
  final double spikeTop = spike.position.y - spike.size.y;

  // Player image info (may be null)
  final bool havePlayerMask = playerMask != null && playerNaturalSize != null;
  final int playerImgW = havePlayerMask ? playerNaturalSize!.x.toInt() : 0;
  final int playerImgH = havePlayerMask ? playerNaturalSize!.y.toInt() : 0;

  // Dynamic sampling for performance
  final double overlapArea = overlap.width * overlap.height;
  final bool fineSample = overlapArea < 400; // e.g. 20x20
  final int stepX = fineSample ? 1 : max(1, (overlap.width / 10).floor());
  final int stepY = fineSample ? 1 : max(1, (overlap.height / 10).floor());

  for (double wy = overlap.top; wy < overlap.bottom; wy += stepY) {
    for (double wx = overlap.left; wx < overlap.right; wx += stepX) {
      final spikeIdx = _indexForWorldPointOnSpike(
        spike,
        wx,
        wy,
        spikeLeft,
        spikeTop,
        spikeImgW,
        spikeImgH,
      );
      if (spikeIdx < 0 || spikeMask[spikeIdx] == 0) continue;

      // If we don't have a player mask, any non-transparent spike pixel is a hit
      if (!havePlayerMask) return true;

      final playerIdx = _indexForWorldPointOnPlayer(
        wx,
        wy,
        playerRect.left,
        playerRect.top,
        playerImgW,
        playerImgH,
        playerRect.width,
        playerRect.height,
      );
      if (playerIdx >= 0 && playerMask![playerIdx] != 0) return true;
    }
  }

  // Fallback: sample the center of the overlap once
  final wx = overlap.left + overlap.width / 2;
  final wy = overlap.top + overlap.height / 2;
  final spikeIdx = _indexForWorldPointOnSpike(
    spike,
    wx,
    wy,
    spikeLeft,
    spikeTop,
    spikeImgW,
    spikeImgH,
  );
  if (spikeIdx >= 0 && spikeMask[spikeIdx] != 0) {
    if (!havePlayerMask) return true;
    final playerIdx = _indexForWorldPointOnPlayer(
      wx,
      wy,
      playerRect.left,
      playerRect.top,
      playerImgW,
      playerImgH,
      playerRect.width,
      playerRect.height,
    );
    if (playerIdx >= 0 && playerMask![playerIdx] != 0) return true;
  }
  return false;
}

// Helper: map a world point (worldX, worldY) into the spike image mask index.
// Returns -1 if the point lies outside the spike's rectangle.
int _indexForWorldPointOnSpike(
  Spike spike,
  double worldX,
  double worldY,
  double spikeLeft,
  double spikeTop,
  int imgW,
  int imgH,
) {
  final localX = worldX - spikeLeft;
  final localY = worldY - spikeTop;
  if (localX < 0 ||
      localY < 0 ||
      localX > spike.size.x ||
      localY > spike.size.y) {
    return -1;
  }
  int imgX = ((localX / spike.size.x) * imgW).floor();
  int imgY = ((localY / spike.size.y) * imgH).floor();
  imgX = max(0, min(imgX, imgW - 1));
  imgY = max(0, min(imgY, imgH - 1));
  return imgY * imgW + imgX;
}

// Map a world point to a player image mask index. Returns -1 if outside.
int _indexForWorldPointOnPlayer(
  double worldX,
  double worldY,
  double playerLeft,
  double playerTop,
  int imgW,
  int imgH,
  double playerWidth,
  double playerHeight,
) {
  final localX = worldX - playerLeft;
  final localY = worldY - playerTop;
  if (localX < 0 || localY < 0 || localX > playerWidth || localY > playerHeight) return -1;
  int imgX = ((localX / playerWidth) * imgW).floor();
  int imgY = ((localY / playerHeight) * imgH).floor();
  imgX = max(0, min(imgX, imgW - 1));
  imgY = max(0, min(imgY, imgH - 1));
  return imgY * imgW + imgX;
}

bool checkPixelPerfectDoorCollision(
  Rect playerRect,
  Rect doorRect,
  Vector2 doorNaturalSize,
  Uint8List doorPixels,
) {
  final overlap = playerRect.intersect(doorRect);
  if (overlap.width <= 0 || overlap.height <= 0) return false;

  final int imgW = doorNaturalSize.x.toInt();
  final int imgH = doorNaturalSize.y.toInt();
  final Uint8List px = doorPixels;

  final int stepX = max(1, (overlap.width / 10).floor());
  final int stepY = max(1, (overlap.height / 10).floor());

  for (double wy = overlap.top; wy < overlap.bottom; wy += stepY) {
    for (double wx = overlap.left; wx < overlap.right; wx += stepX) {
      final localX = wx - doorRect.left;
      final localY = wy - doorRect.top;
      int imgX = ((localX / doorRect.width) * imgW).floor().clamp(0, imgW - 1);
      int imgY = ((localY / doorRect.height) * imgH).floor().clamp(0, imgH - 1);
      final idx = (imgY * imgW + imgX) * 4;
      if (px[idx + 3] > 10) return true;
    }
  }
  return false;
}
