import 'dart:ui' as ui;

// import 'package:flame/parallax.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'obstacles/spikes.dart';
import 'game_api.dart';
import 'collision_utils.dart';

// Helper entry for spikes that slide from off-screen into their final X.
class _SlidingSpikeEntry {
  final Spike spike;
  final double targetX; // final center x position (matching spike.position.x semantics)
  final double speed; // px/s moving leftwards
  final double triggerAtX; // player center X at which the spike starts moving
  bool started = false;
  bool finished = false;
  _SlidingSpikeEntry({
    required this.spike,
    required this.targetX,
    required this.speed,
    required this.triggerAtX,
  });
}

enum DoorState { idle, closing, closed, opening, opened }

class RunnerGame extends FlameGame with TapCallbacks implements GameApi {
  final int? startMap;
  RunnerGame({this.startMap});
  GameState gameState = GameState.intro;
  Player? player;
  SpriteComponent? background;
  SpriteComponent? ground;
  late double groundHeight;
  // Offset visual para levantar el suelo y al jugador (en píxeles)
  double groundVisualOffset = 8.0;
  // Spikes spawned by this scene (so we can remove/respawn on rebuild)
  final List<Spike> spawnedSpikes = [];
  // Player starts glued to the left edge (small padding)
  final double _playerStartX = 0.0;
  // Door & wall (muro) transition state
  PositionComponent? door;
  DoorState _doorState = DoorState.idle;
  bool _doorUsed = false; // ensure it only closes once
  // When true, player input for horizontal movement is ignored.
  bool _controlsLocked = false;
  SpriteComponent? _muroTop;
  SpriteComponent? _muroBottom;
  double _muroSpeed = 420.0; // pixels per second the muro pieces move
  // Ground tiled container for next level
  PositionComponent? groundTiles;
  // Second level / falling tiles state
  bool _secondLevelActive = false;
  // When true, do not trigger falling tiles (used when starting as startMap==2)
  bool _disableFallingWhenStartMap2 = false;
  // Third level state
  bool _thirdLevelActive = false;
  bool _fallTriggered = false;
  double _fallSpeed = 900.0; // px/s for falling tiles
  final List<SpriteComponent> _fallingTiles = [];
  // Sliding spike entries for spikes that come from off-screen
  final List<_SlidingSpikeEntry> _slidingSpikes = [];
  // Void-fall detection and control-lock
  bool _inVoidFalling = false;
  double _voidFallTimer = 0.0;
  final double _voidFallTimeout = 1.2; // seconds before registering death (allow visible fall)

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load a static background sprite that fills the screen and stays
    // behind the game objects (below the ground). We create it with
    // an initial size of zero if the game size isn't ready yet, and
    // resize it in `_buildScene`.
    final uiImage = await images.load('fondo.jpg');
    background = SpriteComponent(
      sprite: Sprite(uiImage),
      size: Vector2.zero(),
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    );
    // Add the background early so it's rendered below later-added components
    add(background!);

    final groundImage = await images.load('piso_mapa.png');

    // Detectar y recortar la parte transparente superior de la imagen del suelo
    final int topOpaque = await _findTopOpaquePixel(groundImage, alphaThreshold: 8);
    Sprite groundSprite;
    if (topOpaque > 0 && topOpaque < groundImage.height) {
      groundSprite = Sprite(
        groundImage,
        srcPosition: Vector2(0, topOpaque.toDouble()),
        srcSize: Vector2(groundImage.width.toDouble(), (groundImage.height - topOpaque).toDouble()),
      );
    } else {
      groundSprite = Sprite(groundImage);
    }

    ground = SpriteComponent(
      sprite: groundSprite,
      size: Vector2.zero(),
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    );
    add(ground!);

    if (size != Vector2.zero()) {
      await _buildScene(size);
    }
    // If requested to start directly at map 2, build the second-level scene
    if (startMap == 2) {
      // ensure door flags are reset and then build level 2
      _doorUsed = false;
      // If we started directly at map 2, disable falling tile triggers for the base ground
      _disableFallingWhenStartMap2 = true;
      // Build the second-level scene immediately
      await _onWallClosed();
      // Ensure the muro state is 'opened' (don't rely on opening animation
      // since there are no muro pieces when starting directly at map 2).
      _doorState = DoorState.opened;
      _controlsLocked = false;
    }
    // Start in intro state, wait for a tap to begin
    gameState = GameState.intro;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != GameState.playing) return;

    // Update sliding spikes movement (they move towards their targetX once triggered)
    if (_slidingSpikes.isNotEmpty && player != null) {
      final double playerCenterX = player!.position.x + player!.size.x / 2.0;
      for (final e in List<_SlidingSpikeEntry>.from(_slidingSpikes)) {
        if (!e.started) {
          if (playerCenterX >= e.triggerAtX) {
            e.started = true;
          } else {
            continue;
          }
        }
        if (!e.finished) {
          // move left towards target
          final double move = e.speed * dt;
          e.spike.position.x = (e.spike.position.x - move);
          if (e.spike.position.x <= e.targetX) {
            e.spike.position.x = e.targetX;
            e.finished = true;
          }
        }
        // Remove entries that finished and whose spike is not in spawnedSpikes anymore
        if (e.finished) {
          // keep the spike in the spawned list for collisions; but drop the entry
          _slidingSpikes.remove(e);
        }
      }
    }

    // If player touches the door trigger, start closing the muro (only once).
    // Allow triggering when the muro is idle or already opened (ready to close again).
    if ((_doorState == DoorState.idle || _doorState == DoorState.opened) && !_doorUsed && player != null && door != null) {
      if (player!.toRect().overlaps(door!.toRect())) {
        // If we're in third level, touching the right door should return to
        // the home screen and request the 'activate_second_door' flow.
        if (_thirdLevelActive) {
          // add an overlay which the UI layer will use to pop with a result
          overlays.add('ReturnHome');
        } else {
          startDoorClose();
        }
      }
    }

    // Animate muro pieces depending on door state
    if (_doorState == DoorState.closing) {
      final double move = _muroSpeed * dt;
      if (_muroTop != null) _muroTop!.position.y += move;
      if (_muroBottom != null) _muroBottom!.position.y -= move;
      // Check if they met or crossed center
      if (_muroTop != null && _muroBottom != null) {
        final double topBottomY = _muroTop!.position.y + _muroTop!.size.y;
        final double bottomTopY = _muroBottom!.position.y;
        if (topBottomY >= bottomTopY) {
          // Snap them to meet exactly in the middle
          final double centerY = size.y / 2.0;
          final double h = _muroTop!.size.y;
          _muroTop!.position.y = centerY - h;
          _muroBottom!.position.y = centerY;
          _doorState = DoorState.closed;
          _onWallClosed();
        }
      }
    } else if (_doorState == DoorState.opening) {
      final double move = _muroSpeed * dt;
      if (_muroTop != null) _muroTop!.position.y -= move;
      if (_muroBottom != null) _muroBottom!.position.y += move;
      // If they are fully off-screen, finish opening
      if (_muroTop != null && _muroBottom != null) {
        if (_muroTop!.position.y + _muroTop!.size.y <= 0 && _muroBottom!.position.y >= size.y) {
          // Finished opening
          _doorState = DoorState.opened;
          // cleanup muro pieces
          _muroTop!.removeFromParent();
          _muroBottom!.removeFromParent();
          _muroTop = null;
          _muroBottom = null;
          // Keep the `door` component (it may be the newly-created exit door).
          // Allow the door to be used again for subsequent transitions
            _doorUsed = false;
            // Re-enable controls now that opening finished
            _controlsLocked = false;
        }
      }
    }

    // Second level: trigger falling tiles when player reaches middle of screen
    if (_secondLevelActive && !_fallTriggered && player != null) {
      final double playerCenterX = player!.position.x + player!.size.x / 2.0;
      if (playerCenterX >= size.x / 2.0) {
        _triggerFallingTiles();
      }
    }

    // Update falling tiles movement
    if (_fallingTiles.isNotEmpty) {
      final double move = _fallSpeed * dt;
      for (final t in List<SpriteComponent>.from(_fallingTiles)) {
        t.position.y += move;
        if (t.position.y > size.y + 200) {
          _fallingTiles.remove(t);
          t.removeFromParent();
        }
      }
    }

    // Independent void-fall detection for second level: always check while second level active
    if (_secondLevelActive && player != null) {
      final double leftX = player!.position.x;
      final double rightX = player!.position.x + player!.size.x;
      final surfaceY = surfaceYAt(leftX, rightX);

      if (surfaceY == null) {
        // start/continue void-fall timer and lock horizontal control
        _voidFallTimer += dt;
        if (!_inVoidFalling) {
          _inVoidFalling = true;
          // Do NOT zero horizontal velocity here so the player preserves
          // horizontal momentum when stepping off a ledge. Disable player
          // requested movement inputs so new input isn't applied while
          // in the void-fall state.
          player!.moveLeft = false;
          player!.moveRight = false;
        }
        // If the player has been falling for longer than timeout or already left screen, die
        if (_voidFallTimer >= _voidFallTimeout || player!.position.y > size.y) {
          _onSecondLevelDeath();
        }
      } else {
        // There is surface under player: cancel void-fall state
        _voidFallTimer = 0.0;
        _inVoidFalling = false;
      }
    }

    // Check collisions between player and static spikes
    if (player != null) {
      final playerRect = player!.toRect();
      for (final s in spawnedSpikes) {
        if (checkPixelPerfectCollision(playerRect, s, playerMask: player!.alphaMask, playerNaturalSize: player!.naturalSize)) {
          onPlayerDied();
          break;
        }
      }
    }
  }

  /// Start the door closing animation: spawn two muro pieces (top & bottom)
  Future<void> startDoorClose() async {
    // allow starting the close animation when muro is idle or already opened
    if (!(_doorState == DoorState.idle || _doorState == DoorState.opened) || _doorUsed) return;
    _doorState = DoorState.closing;

    // Stop player horizontal movement while the door closes
    if (player != null) {
      player!.velocity.x = 0;
      player!.moveLeft = false;
      player!.moveRight = false;
      // Lock controls so player can't re-enable movement while transition runs
      _controlsLocked = true;
    }

    // Load muro image and create top/bottom sprites
    try {
      // Choose muro images depending on context. For startMap==2, use the
      // specialized top/bottom images so they visually meet in the middle.
      String topName = 'muro.png';
      String bottomName = 'muro.png';
      if (startMap == 2) {
        topName = 'muro_invert_nvl1.png';
        bottomName = 'muro_nvl1.png';
      }
      await images.load(topName);
      await images.load(bottomName);
      final imgTop = images.fromCache(topName);
      final imgBottom = images.fromCache(bottomName);
      final double halfH = size.y / 2.0;

      final Sprite sprTop = Sprite(imgTop);
      final Sprite sprBottom = Sprite(imgBottom);
      // Top muro: starts above the screen
      _muroTop = SpriteComponent(
        sprite: sprTop,
        size: Vector2(size.x, halfH),
        position: Vector2(0, -halfH),
        anchor: Anchor.topLeft,
      );
      // Bottom muro: starts below the screen
      _muroBottom = SpriteComponent(
        sprite: sprBottom,
        size: Vector2(size.x, halfH),
        position: Vector2(0, size.y),
        anchor: Anchor.topLeft,
      );
      // Add above other components so they visually cover the scene
      add(_muroTop!);
      add(_muroBottom!);
      // mark used so we don't trigger closing again
      _doorUsed = true;
    } catch (e) {
      // If image missing, still set closing=false to avoid stuck state
      _doorState = DoorState.idle;
    }
  }

  /// Called once the muro has fully closed (met in middle).
  Future<void> _onWallClosed() async {
    // If we were NOT in second-level mode, build the second level here.
    if (!_secondLevelActive) {
      // Build tiled ground from five images repeated to cover 8x width
      // Remove background and any spikes for the next level (leave only the ground)
      if (background != null) {
        background!.removeFromParent();
        background = null;
      }
      for (final s in spawnedSpikes) {
        s.removeFromParent();
      }
      spawnedSpikes.clear();

      final double targetWidth = size.x * 8.0;
      final Vector2 groundPos = Vector2(0, size.y - groundHeight - groundVisualOffset);
      if (ground != null) {
        ground!.removeFromParent();
        ground = null;
      }
      if (groundTiles != null) {
        groundTiles!.removeFromParent();
        groundTiles = null;
      }

      groundTiles = PositionComponent(position: groundPos, size: Vector2(targetWidth, groundHeight), anchor: Anchor.topLeft);

      // names and order for tiles
      // If the game was started directly from the second door (startMap==2),
      // build the second-level ground using the special part-2 floor image.
      final List<String> tileNames = (startMap == 2)
        ? ['piso_nvl1_pt2.png']
        : [
            'piso_1_mapa.png',
            'piso_2_mapa.png',
            'piso_3_mapa.png',
            'piso_14_mapa.png',
            'piso_5_mapa.png',
          ];

      double cursorX = 0.0;
      int idx = 0;
      while (cursorX < targetWidth) {
        final name = tileNames[idx % tileNames.length];
        ui.Image? img;
        try {
          await images.load(name);
          img = images.fromCache(name);
        } catch (e) {
          img = null;
        }
        if (img == null) { idx++; continue; }

        final int topOpaque = await _findTopOpaquePixel(img, alphaThreshold: 8);
        final int naturalH = (img.height - topOpaque).clamp(1, img.height);
        final Sprite tileSprite = (topOpaque > 0 && topOpaque < img.height)
          ? Sprite(img, srcPosition: Vector2(0, topOpaque.toDouble()), srcSize: Vector2(img.width.toDouble(), naturalH.toDouble()))
          : Sprite(img);

        final double tileScale = groundHeight / naturalH;
        final double tileW = img.width * tileScale;

        final SpriteComponent tileComp = SpriteComponent(
          sprite: tileSprite,
          size: Vector2(tileW, groundHeight),
          position: Vector2(cursorX, 0),
          anchor: Anchor.topLeft,
        );
        groundTiles!.add(tileComp);
        cursorX += tileW;
        idx++;
      }

      // Add groundTiles to the game beneath the player: remove player, add groundTiles, re-add player
      final Player? savedPlayer = player;
      if (savedPlayer != null) remove(savedPlayer);
      add(groundTiles!);

      // Create a visible left-side door (entrance)
      final double doorWidth = 40.0;
      final double doorHeight = groundHeight;
      final PositionComponent leftDoor = PositionComponent(
        position: Vector2(0, groundPos.y - doorHeight),
        size: Vector2(doorWidth, doorHeight),
        anchor: Anchor.topLeft,
      );
      leftDoor.add(RectangleComponent(
        size: Vector2(doorWidth, doorHeight),
        paint: Paint()..color = Colors.brown,
        anchor: Anchor.topLeft,
      ));
      add(leftDoor);

      // Create an exit door at the far right of the tiled ground that will
      // trigger the next transition (Nivel 3)
      final PositionComponent exitDoor = PositionComponent(
        // place the exit door at the right edge of the visible screen
        position: Vector2(size.x - doorWidth, groundPos.y - doorHeight),
        size: Vector2(doorWidth, doorHeight),
        anchor: Anchor.topLeft,
      );
      exitDoor.add(RectangleComponent(
        size: Vector2(doorWidth, doorHeight),
        paint: Paint()..color = Colors.brown,
        anchor: Anchor.topLeft,
      ));
      add(exitDoor);

      // Make the exit door the active trigger for startDoorClose
      final oldDoor = door;
      door = exitDoor;
      if (oldDoor != null) oldDoor.removeFromParent();

      if (savedPlayer != null) {
        // place player to the right of the left door so it's "junto a la puerta"
        savedPlayer.position = Vector2(doorWidth + 4.0, size.y - groundHeight - savedPlayer.size.y - groundVisualOffset);
        savedPlayer.velocity.x = 0;
        savedPlayer.moveLeft = false;
        savedPlayer.moveRight = false;
        add(savedPlayer);
      }

      // Start opening animation (reverse of closing)
      _doorState = DoorState.opening;
      // mark that second level is now active and allow future transitions
      _secondLevelActive = true;
      _doorUsed = false;
      // Re-enable player controls after second-level build
      _controlsLocked = false;
      return;
    }

    // If we ARE in second-level mode and next level is not yet created,
    // then this closure corresponds to the transition into Nivel 3.
    if (_secondLevelActive && !_thirdLevelActive) {
      // Clean up second-level specific state
      _secondLevelActive = false;
      _fallTriggered = false;
      for (final t in _fallingTiles) t.removeFromParent();
      _fallingTiles.clear();
      if (groundTiles != null) {
        groundTiles!.removeFromParent();
        groundTiles = null;
      }
      for (final s in spawnedSpikes) s.removeFromParent();
      spawnedSpikes.clear();

      // Build Nivel 3 as a tiled ground repeating a 6-tile sequence across 8x width
      final double targetWidth = size.x * 8.0;
      final Vector2 groundPos = Vector2(0, size.y - groundHeight - groundVisualOffset);
      if (ground != null) {
        ground!.removeFromParent();
        ground = null;
      }
      if (groundTiles != null) {
        groundTiles!.removeFromParent();
        groundTiles = null;
      }

      groundTiles = PositionComponent(position: groundPos, size: Vector2(targetWidth, groundHeight), anchor: Anchor.topLeft);

      // If we started the game from the second door (startMap==2), build a
      // special Nivel 2 floor using `piso_nvl2_pt2.png` occupying 25% of the
      // screen width, centered. Otherwise build the regular tiled ground.
      if (startMap == 2) {
        final String special = 'piso_nvl2_pt2.png';
        ui.Image? img;
        try {
          await images.load(special);
          img = images.fromCache(special);
        } catch (_) {
          img = null;
        }
        if (img != null) {
          final int topOpaque = await _findTopOpaquePixel(img, alphaThreshold: 8);
          final int naturalH = (img.height - topOpaque).clamp(1, img.height);
          final Sprite tileSprite = (topOpaque > 0 && topOpaque < img.height)
            ? Sprite(img, srcPosition: Vector2(0, topOpaque.toDouble()), srcSize: Vector2(img.width.toDouble(), naturalH.toDouble()))
            : Sprite(img);

          // target width is 25% of visible canvas. Place the special tile
          // pinned to the LEFT of the visible screen so the player sees it
          // at the start of the level. Previously it was centered across the
          // whole long tiled ground and ended up off-screen.
          final double tileW = size.x * 0.25;
          final SpriteComponent tileComp = SpriteComponent(
            sprite: tileSprite,
            size: Vector2(tileW, groundHeight),
            // pin to the left edge of the VISIBLE canvas
            position: Vector2(0, 0),
            anchor: Anchor.topLeft,
          );
          groundTiles!.add(tileComp);
        }
      } else {
        final List<String> tileNamesLevel3 = [
          'piso1_2_chico.png',
          'piso2_2_chico.png',
          'piso3_2_chico.png',
          'piso4_2_chico.png',
          'piso5_2_chico.png',
          'piso6_2_chico.png',
        ];

        double cursorX = 0.0;
        int idx = 0;
        while (cursorX < targetWidth) {
          final name = tileNamesLevel3[idx % tileNamesLevel3.length];
          ui.Image? img;
          try {
            await images.load(name);
            img = images.fromCache(name);
          } catch (_) {
            img = null;
          }
          if (img == null) { idx++; continue; }

          final int topOpaque = await _findTopOpaquePixel(img, alphaThreshold: 8);
          final int naturalH = (img.height - topOpaque).clamp(1, img.height);
          final Sprite tileSprite = (topOpaque > 0 && topOpaque < img.height)
            ? Sprite(img, srcPosition: Vector2(0, topOpaque.toDouble()), srcSize: Vector2(img.width.toDouble(), naturalH.toDouble()))
            : Sprite(img);

          final double tileScale = groundHeight / naturalH;
          final double tileW = img.width * tileScale;

          final SpriteComponent tileComp = SpriteComponent(
            sprite: tileSprite,
            size: Vector2(tileW, groundHeight),
            position: Vector2(cursorX, 0),
            anchor: Anchor.topLeft,
          );
          groundTiles!.add(tileComp);
          cursorX += tileW;
          idx++;
        }
      }

      add(groundTiles!);

      // Teleport player to start of Nivel 3
      final Player? savedPlayer = player;
      if (savedPlayer != null) {
        remove(savedPlayer);
        savedPlayer.position = Vector2(_playerStartX, size.y - groundHeight - savedPlayer.size.y - groundVisualOffset);
        savedPlayer.velocity.x = 0;
        savedPlayer.moveLeft = false;
        savedPlayer.moveRight = false;
        add(savedPlayer);
      }

      // Allow level 3 obstacles to spawn: reuse spike spawner by ensuring flags
      _thirdLevelActive = true;
      _secondLevelActive = false;
      // If this special Nivel 3 was created because we started from the
      // second door (startMap==2) we intentionally do NOT spawn spikes so
      // the small special floor remains safe; otherwise spawn the usual
      // Nivel 3 spikes.
      if (startMap == 2) {
        // Ensure no lingering spikes exist
        for (final s in spawnedSpikes) s.removeFromParent();
        spawnedSpikes.clear();
      } else {
        await _spawnThreeSpikes(size);
      }

      // Open the muro to reveal Nivel 3
      _doorState = DoorState.opening;
      // ensure door flag reset
      _doorUsed = false;
      // Re-enable player controls after Nivel 3 build
      _controlsLocked = false;
      return;
    }
  }

  /// Find two tiles near the player and make them fall (so they create a hole).
  void _triggerFallingTiles() {
    if (groundTiles == null) return;
    if (_disableFallingWhenStartMap2) return;
    if (player == null) return;
    final double playerCenterX = player!.position.x + player!.size.x / 2.0;
    // find tile whose global x-range contains playerCenterX
    final tiles = groundTiles!.children.whereType<SpriteComponent>().toList();
    int found = -1;
    for (int i = 0; i < tiles.length; i++) {
      final t = tiles[i];
      final double tileGlobalX = groundTiles!.position.x + t.position.x;
      if (playerCenterX >= tileGlobalX && playerCenterX < tileGlobalX + t.size.x) {
        found = i;
        break;
      }
    }
    if (found == -1) return;

    // choose this tile and the next two (right-adjacent) to fall so three contiguous
    final List<int> indices = [found, (found + 1) % tiles.length, (found + 2) % tiles.length];
    for (final idx in indices) {
      final t = tiles[idx];
      // compute global position
      final globalPos = groundTiles!.position + t.position;
      // remove from groundTiles and add to root so it is in front
      groundTiles!.remove(t);
      t.position = globalPos;
      add(t);
      _fallingTiles.add(t);
    }

    _fallTriggered = true;
  }

  void _onSecondLevelDeath() {
    if (!_secondLevelActive) return;
    // Use existing death flow
    onPlayerDied();
    // Do NOT auto-restart the level here. Wait for the player to press
    // the "Reintentar Nivel 2" button in the GameOver overlay which will
    // call `restartSecondLevel()` and properly rebuild the second level.
  }

  /// Rebuilds second level state (tiles, door, player position) when restarting
  Future<void> _restartSecondLevel() async {
    // cleanup existing scene parts
    pauseEngine();
    // Remove game over overlay if still present
    overlays.remove('GameOver');
    
    // remove muro pieces if any
    _muroTop?.removeFromParent();
    _muroBottom?.removeFromParent();
    _muroTop = null;
    _muroBottom = null;
    _doorState = DoorState.idle;

    // remove groundTiles and any tiles
    if (groundTiles != null) {
      groundTiles!.removeFromParent();
      groundTiles = null;
    }
    for (final t in _fallingTiles) {
      t.removeFromParent();
    }
    _fallingTiles.clear();
    _fallTriggered = false;

    // ensure no background and spikes
    background?.removeFromParent();
    background = null;
    for (final s in spawnedSpikes) s.removeFromParent();
    spawnedSpikes.clear();

    // build second level again by reusing the onWallClosed tile-creation logic
    // we call a trimmed copy here: create tiles and left door and teleport player
    final double targetWidth = size.x * 8.0;
    final Vector2 groundPos = Vector2(0, size.y - groundHeight - groundVisualOffset);
    groundTiles = PositionComponent(position: groundPos, size: Vector2(targetWidth, groundHeight), anchor: Anchor.topLeft);

    final List<String> tileNames = [
      'piso_1_mapa.png',
      'piso_2_mapa.png',
      'piso_3_mapa.png',
      'piso_14_mapa.png',
      'piso_5_mapa.png',
    ];

    double cursorX = 0.0;
    int idx = 0;
    while (cursorX < targetWidth) {
      final name = tileNames[idx % tileNames.length];
      ui.Image? img;
      try {
        await images.load(name);
        img = images.fromCache(name);
      } catch (_) {
        img = null;
      }
      if (img == null) { idx++; continue; }
      final int topOpaque = await _findTopOpaquePixel(img, alphaThreshold: 8);
      final int naturalH = (img.height - topOpaque).clamp(1, img.height);
      final Sprite tileSprite = (topOpaque > 0 && topOpaque < img.height)
        ? Sprite(img, srcPosition: Vector2(0, topOpaque.toDouble()), srcSize: Vector2(img.width.toDouble(), naturalH.toDouble()))
        : Sprite(img);
      final double tileScale = groundHeight / naturalH;
      final double tileW = img.width * tileScale;
      final SpriteComponent tileComp = SpriteComponent(
        sprite: tileSprite,
        size: Vector2(tileW, groundHeight),
        position: Vector2(cursorX, 0),
        anchor: Anchor.topLeft,
      );
      groundTiles!.add(tileComp);
      cursorX += tileW;
      idx++;
    }

    final Player? savedPlayer = player;
    if (savedPlayer != null) remove(savedPlayer);
    add(groundTiles!);

    // create left door
    final double doorWidth = 40.0;
    final PositionComponent newDoor = PositionComponent(
      position: Vector2(0, groundPos.y - groundHeight),
      size: Vector2(doorWidth, groundHeight),
      anchor: Anchor.topLeft,
    );
    newDoor.add(RectangleComponent(
      size: Vector2(doorWidth, groundHeight),
      paint: Paint()..color = Colors.brown,
      anchor: Anchor.topLeft,
    ));
    add(newDoor);

    // create exit door at the far right of the tiled ground (so player can trigger transition)
    final PositionComponent exitDoor = PositionComponent(
      // place the exit door at the right edge of the visible screen
      position: Vector2(size.x - doorWidth, groundPos.y - groundHeight),
      size: Vector2(doorWidth, groundHeight),
      anchor: Anchor.topLeft,
    );
    exitDoor.add(RectangleComponent(
      size: Vector2(doorWidth, groundHeight),
      paint: Paint()..color = Colors.brown,
      anchor: Anchor.topLeft,
    ));
    add(exitDoor);

    // Make the exit door the active trigger
    door = exitDoor;

    if (savedPlayer != null) {
      savedPlayer.position = Vector2(doorWidth + 4.0, size.y - groundHeight - savedPlayer.size.y - groundVisualOffset);
      savedPlayer.velocity.x = 0;
      savedPlayer.moveLeft = false;
      savedPlayer.moveRight = false;
      add(savedPlayer);
    }

    // re-enable second level and reset void-fall state so controls work
    _secondLevelActive = true;
    // Ensure the door can be used for transition (not marked as already used)
    _doorUsed = false;
    _inVoidFalling = false;
    _voidFallTimer = 0.0;
    // Ensure game is in playing state and no spikes are spawned
    gameState = GameState.playing;
    // Unlock controls after restart
    _controlsLocked = false;
    resumeEngine();
  }

  /// Public API to restart second level (used by UI overlay)
  Future<void> restartSecondLevel() async {
    await _restartSecondLevel();
  }

  /// Whether the game is currently in second-level mode (used by overlays)
  bool get isSecondLevelActive => _secondLevelActive;

  /// Number of doors that should be considered unlocked when returning to home.
  /// Simple heuristic: if the game reached second or third level, unlock door 2.
  int get unlockedDoorsCount {
    if (_thirdLevelActive || _secondLevelActive) return 2;
    return 1;
  }

  Future<int> _findTopOpaquePixel(ui.Image image, {int alphaThreshold = 8}) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return 0;
    final Uint8List pixels = byteData.buffer.asUint8List();
    final int w = image.width;
    final int h = image.height;
    for (int y = 0; y < h; y++) {
      final int rowStart = y * w * 4;
      for (int x = 0; x < w; x++) {
        final int alpha = pixels[rowStart + x * 4 + 3];
        if (alpha > alphaThreshold) return y;
      }
    }
    return 0;
  }

  /// Returns [top, bottom] row indices (inclusive) of the opaque pixel bounds.
  /// If no opaque pixels found returns [-1, -1].
  Future<List<int>> _findOpaqueBounds(ui.Image image, {int alphaThreshold = 8}) async {
    final bd = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return [-1, -1];
    final Uint8List pixels = bd.buffer.asUint8List();
    final int w = image.width;
    final int h = image.height;
    int top = -1;
    int bottom = -1;
    for (int y = 0; y < h; y++) {
      final int rowStart = y * w * 4;
      for (int x = 0; x < w; x++) {
        if (pixels[rowStart + x * 4 + 3] > alphaThreshold) {
          top = y;
          break;
        }
      }
      if (top != -1) break;
    }
    if (top == -1) return [-1, -1];
    for (int y = h - 1; y >= 0; y--) {
      final int rowStart = y * w * 4;
      for (int x = 0; x < w; x++) {
        if (pixels[rowStart + x * 4 + 3] > alphaThreshold) {
          bottom = y;
          break;
        }
      }
      if (bottom != -1) break;
    }
    return [top, bottom];
  }

  /// Returns the Y coordinate (top) of the surface under the horizontal range [left..right].
  /// If there is no surface (no ground or tiles) returns null.
  double? surfaceYAt(double left, double right) {
    // If a single ground SpriteComponent exists, use its top Y
    if (ground != null) {
      return ground!.position.y;
    }

    // If tiled ground exists, check its children tiles
    if (groundTiles != null) {
      for (final c in groundTiles!.children.whereType<SpriteComponent>()) {
        final double tileGlobalX = groundTiles!.position.x + c.position.x;
        final double tileGlobalRight = tileGlobalX + c.size.x;
        // overlap test between [left,right] and [tileGlobalX,tileGlobalRight]
        if (!(right <= tileGlobalX || left >= tileGlobalRight)) {
          // tile overlaps horizontally; return top Y of the tile (groundTiles' Y)
          return groundTiles!.position.y + c.position.y;
        }
      }
    }

    // no surface under this horizontal range
    return null;
  }



  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _buildScene(canvasSize);
  }

    Future<void> _buildScene(Vector2 canvasSize) async {

      // Establece una altura fija para el suelo

      groundHeight = canvasSize.y * 0.25;

  

      if (background != null) {

        background!.size = canvasSize;

      }

    if (ground != null) {
      ground!.size = Vector2(canvasSize.x, groundHeight);
      ground!.position = Vector2(0, canvasSize.y - groundHeight - groundVisualOffset);
    }

    // Si el jugador ya existe, lo elimina para recrearlo
    if (player != null) {
      remove(player!);
    }

    // Crea y posiciona al jugador (tamaño aumentado a 64x64)
    player = Player(size: Vector2(58, 64));
    player!.position =
      Vector2(_playerStartX, canvasSize.y - groundHeight - player!.size.y - groundVisualOffset);
    add(player!);

    // Add a simple visible door trigger attached to the right edge (near ground)
    final double doorWidth = 40.0;
    final double doorHeight = groundHeight; // tall door occupying ground area
    final double groundY = canvasSize.y - groundHeight - groundVisualOffset;
    door = PositionComponent(
      position: Vector2(canvasSize.x - doorWidth, groundY - doorHeight),
      size: Vector2(doorWidth, doorHeight),
      anchor: Anchor.topLeft,
    );
    // Add a visible rectangle so the door is noticeable during testing
    door!.add(RectangleComponent(
      size: Vector2(doorWidth, doorHeight),
      paint: Paint()..color = Colors.brown,
      anchor: Anchor.topLeft,
    ));
    add(door!);

    // Spawn three spikes after player created
    await _spawnThreeSpikes(canvasSize);
  }





  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.intro) {
      // keep tap-to-start in intro, but DO NOT treat taps as jump inputs
      startGame();
    }
  }

  void startGame() {
    gameState = GameState.playing;
    overlays.remove('intro');
    resumeEngine();
  }

  void resetGame() {
    // Reiniciar estado y reconstruir la escena
    gameState = GameState.playing;
    // Remove game over overlay if present and restore controls
    overlays.remove('GameOver');
    overlays.add('Controls');
    _buildScene(size);
    if (player != null) {
      player!.invulnerable = 1.0; // Dar un segundo de invulnerabilidad
    }
    // Ensure controls are unlocked when resetting the game
    _controlsLocked = false;
    resumeEngine();
  }



  void moveLeftStart() {
    if (gameState == GameState.playing && !_controlsLocked) player?.moveLeft = true;
  }
  void moveRightStart() {
    if (gameState == GameState.playing && !_controlsLocked) player?.moveRight = true;
  }
  void moveStop() {
    player?.moveLeft = false;
    player?.moveRight = false;
  }

  void jump() {
    if (gameState == GameState.playing) player?.jump();
  }

  @override
  void onPlayerDied() {
    // Prevent multiple triggers
    if (gameState == GameState.gameOver) return;
    gameState = GameState.gameOver;
    pauseEngine();
    // Show overlay (defined in main.dart)
    overlays.add('GameOver');
  }

  Future<void> _spawnThreeSpikes(Vector2 canvasSize) async {
    // Do NOT spawn spikes if we are in second level
    if (_secondLevelActive) return;

    // Remove previously spawned spikes
    for (final s in spawnedSpikes) {
      s.removeFromParent();
    }
    spawnedSpikes.clear();

    if (player == null) return;

    final double visibleTop = canvasSize.y - groundHeight - groundVisualOffset;

    // images to use in order. Use level-3 variants when in Nivel 3, otherwise keep original
    final names = _thirdLevelActive
      ? [
          'pinchos_tres_nvl2.png',
          'pinchos_dos_nvl2.png',
          'pinchos_tres_nvl2.png',
        ]
      : [
          'pinchos_tres_mapa.png',
          'pinchos_dos_mapa.png',
          'pinchos_tres_mapa.png',
        ];

    // Load all images first
    final List<ui.Image> imgs = [];
    for (final n in names) {
      try {
        await images.load(n);
        imgs.add(images.fromCache(n));
      } catch (_) {
        // skip missing images
      }
    }

    if (imgs.isEmpty) return;

    // Jump physics approximation (same as SpikeManager)
    final double playerJumpSpeed = 420.0;
    final double playerGravity = 900.0;
    final double maxJump = (playerJumpSpeed * playerJumpSpeed) / (2 * playerGravity);

    // start a bit to the right of player so spikes don't spawn on top
    double cursorX = _playerStartX + (player!.size.x) + 120.0;
    final double canvasWidth = canvasSize.x;
    final double marginRight = canvasWidth * 0.08;

    for (int i = 0; i < imgs.length; i++) {
      final img = imgs[i];
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null) continue;
      final Uint8List pixels = bd.buffer.asUint8List();
      final int imgW = img.width;

      // Find the opaque bounds (top..bottom) so we can crop out transparent padding
      final bounds = await _findOpaqueBounds(img, alphaThreshold: 10);
      if (bounds[0] == -1) continue; // nothing visible
      final int top = bounds[0];
      final int bottom = bounds[1];
      final int visibleH = bottom - top + 1;

      // Build cropped pixels RGBA and alpha mask for visible area
      final Uint8List croppedPixels = Uint8List(imgW * visibleH * 4);
      final Uint8List alphaMask = Uint8List(imgW * visibleH);
      for (int y = 0; y < visibleH; y++) {
        final int srcRow = (top + y) * imgW * 4;
        final int dstRow = y * imgW * 4;
        for (int x = 0; x < imgW; x++) {
          final int sIdx = srcRow + x * 4;
          final int dIdx = dstRow + x * 4;
          croppedPixels[dIdx] = pixels[sIdx];
          croppedPixels[dIdx + 1] = pixels[sIdx + 1];
          croppedPixels[dIdx + 2] = pixels[sIdx + 2];
          croppedPixels[dIdx + 3] = pixels[sIdx + 3];
          alphaMask[y * imgW + x] = pixels[sIdx + 3] > 10 ? 1 : 0;
        }
      }

      final Vector2 natural = Vector2(imgW.toDouble(), visibleH.toDouble());
      final double spikeHeight = (min(groundHeight * 0.5, maxJump * 0.6)).clamp(20.0, groundHeight);
      final double spikeScale = spikeHeight / natural.y;
      final double spikeWidth = natural.x * spikeScale;

      // ensure cursorX + spikeWidth doesn't go beyond canvas - marginRight
      if (cursorX + spikeWidth + marginRight > canvasWidth) {
        // shift cursor back so last spike fits
        cursorX = (canvasWidth - marginRight) - spikeWidth - (imgs.length - i) * (spikeWidth * 1.6);
        if (cursorX < _playerStartX + player!.size.x + 40) {
          cursorX = _playerStartX + player!.size.x + 40;
        }
      }

      // create a sprite that uses only the visible portion so its bottom lines up with the ground
      final Sprite croppedSprite = Sprite(
        img,
        srcPosition: Vector2(0, top.toDouble()),
        srcSize: Vector2(imgW.toDouble(), visibleH.toDouble()),
      );
      Spike spike;
      // If we're in Nivel 3 (third level) and this is the second spike, make it slide
      // from the right when the player approaches the first spike.
      if (_thirdLevelActive && i == 1 && spawnedSpikes.isNotEmpty) {
        final double targetCenterX = cursorX + spikeWidth / 2;
        final double startX = canvasWidth + spikeWidth; // off-screen to the right
        spike = Spike(
          sprite: croppedSprite,
          position: Vector2(startX, visibleTop + 1.0),
          size: Vector2(spikeWidth, spikeHeight),
          anchor: Anchor.bottomCenter,
          pixels: croppedPixels,
          alphaMask: alphaMask,
          naturalSize: natural,
        );
        spawnedSpikes.add(spike);
        add(spike);
        // Determine trigger point based on first spike's center
        final Spike firstSpike = spawnedSpikes[0];
        final double firstCenter = firstSpike.position.x; // bottomCenter stores center x
        final double triggerAt = firstCenter - 60.0; // when player center reaches this X, start movement
        _slidingSpikes.add(_SlidingSpikeEntry(
          spike: spike,
          targetX: targetCenterX,
          speed: 700.0,
          triggerAtX: triggerAt,
        ));
      } else {
        spike = Spike(
          sprite: croppedSprite,
          // place bottom of spike at visibleTop + small overlap so it doesn't look floating
          position: Vector2(cursorX + spikeWidth / 2, visibleTop + 1.0),
          size: Vector2(spikeWidth, spikeHeight),
          anchor: Anchor.bottomCenter,
          pixels: croppedPixels,
          alphaMask: alphaMask,
          naturalSize: natural,
        );
        spawnedSpikes.add(spike);
        add(spike);
      }

      // gap large enough for player to jump: at least 1.6 * player width
      // give a bit more space between spikes so the player can jump comfortably
      final double gapMultiplier = 2.2;
      final double gap = max(player!.size.x * gapMultiplier, spikeWidth * gapMultiplier);
      cursorX += spikeWidth + gap;
    }
  }
}

class Player extends PositionComponent with HasGameRef<RunnerGame> {
  Vector2 velocity = Vector2.zero();
  bool moveLeft = false;
  bool moveRight = false;
  double invulnerable = 0.0;
  // Pixel mask for the player's visible pixels (alpha mask).
  Uint8List? alphaMask;
  Vector2? naturalSize;

  final double acceleration = 1200;
  final double maxSpeed = 350;
  final double friction = 600;
  final double gravity = 900;
  final double jumpSpeed = -380;

  // Temporizador para el buffer de salto (0.1 segundos)
  double _jumpBufferTimer = 0.0;

  Player({Vector2? position, Vector2? size}) : super(position: position ?? Vector2.zero(), size: size ?? Vector2(64, 64));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.topLeft;
    // Try to load the sprite image for the player. If missing, fall back to a red rectangle.
    try {
      await gameRef.images.load('Personaje_quieto.png');
      final ui.Image img = gameRef.images.fromCache('Personaje_quieto.png');
      // Extract alpha mask and visible bounds so we can perform pixel-perfect collisions
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd != null) {
        final pixels = bd.buffer.asUint8List();
        final int imgW = img.width;
        final int imgH = img.height;
        int top = -1;
        int bottom = -1;
        for (int y = 0; y < imgH; y++) {
          final int rowStart = y * imgW * 4;
          for (int x = 0; x < imgW; x++) {
            if (pixels[rowStart + x * 4 + 3] > 10) {
              top = y;
              break;
            }
          }
          if (top != -1) break;
        }
        if (top != -1) {
          for (int y = imgH - 1; y >= 0; y--) {
            final int rowStart = y * imgW * 4;
            for (int x = 0; x < imgW; x++) {
              if (pixels[rowStart + x * 4 + 3] > 10) {
                bottom = y;
                break;
              }
            }
            if (bottom != -1) break;
          }
        }
        if (top == -1 || bottom == -1) {
          top = 0;
          bottom = imgH - 1;
        }
        final int visibleH = bottom - top + 1;
        final Uint8List mask = Uint8List(imgW * visibleH);
        for (int y = 0; y < visibleH; y++) {
          final int srcRow = (top + y) * imgW * 4;
          final int dstRow = y * imgW;
          for (int x = 0; x < imgW; x++) {
            final int a = pixels[srcRow + x * 4 + 3];
            mask[dstRow + x] = a > 10 ? 1 : 0;
          }
        }
        alphaMask = mask;
        naturalSize = Vector2(imgW.toDouble(), visibleH.toDouble());

        final Sprite cropped = Sprite(img, srcPosition: Vector2(0, top.toDouble()), srcSize: Vector2(imgW.toDouble(), visibleH.toDouble()));
        add(SpriteComponent(
          sprite: cropped,
          size: size,
          position: Vector2.zero(),
          anchor: Anchor.topLeft,
        ));
      } else {
        add(SpriteComponent(
          sprite: Sprite(img),
          size: size,
          position: Vector2.zero(),
          anchor: Anchor.topLeft,
        ));
      }
    } catch (e) {
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.red,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Actualizar el temporizador del buffer de salto
    if (_jumpBufferTimer > 0) {
      _jumpBufferTimer -= dt;
    }

    if (gameRef.gameState != GameState.playing) {
      // Si el juego no está en 'playing', no actualizar movimiento.
      // Aplicar fricción para que el personaje se detenga.
      if (velocity.x > 0) {
        velocity.x = (velocity.x - friction * dt).clamp(0, maxSpeed);
      } else if (velocity.x < 0) {
        velocity.x = (velocity.x + friction * dt).clamp(-maxSpeed, 0);
      }
      return;
    }
    // If the game detected that the player is falling into void, disable horizontal input
    if (gameRef._inVoidFalling) {
      // apply friction to gradually stop horizontal movement
      if (velocity.x > 0) {
        velocity.x = (velocity.x - friction * dt).clamp(0, maxSpeed);
      } else if (velocity.x < 0) {
        velocity.x = (velocity.x + friction * dt).clamp(-maxSpeed, 0);
      }
    } else {
      if (moveLeft) {
        velocity.x = (velocity.x - acceleration * dt).clamp(-maxSpeed, maxSpeed);
      } else if (moveRight) {
        velocity.x = (velocity.x + acceleration * dt).clamp(-maxSpeed, maxSpeed);
      } else {
        if (velocity.x > 0) {
          velocity.x = (velocity.x - friction * dt).clamp(0, maxSpeed);
        } else if (velocity.x < 0) {
          velocity.x = (velocity.x + friction * dt).clamp(-maxSpeed, 0);
        }
      }
    }

    velocity.y += gravity * dt;
    position += velocity * dt;

    // Query the game for the surface under the player's horizontal span.
    final double leftX = position.x;
    final double rightX = position.x + size.x;
    final surfaceY = gameRef.surfaceYAt(leftX, rightX);
    if (surfaceY != null) {
      // If player's bottom is at/ below the surface top, snap to it.
      if (position.y + size.y >= surfaceY - 0.5) {
        position.y = surfaceY - size.y;
        velocity.y = 0;
        // If jump buffer active, jump now
        if (_jumpBufferTimer > 0) {
          velocity.y = jumpSpeed;
          _jumpBufferTimer = 0.0;
        }
      }
    }

    if (position.x < 0) {
      position.x = 0;
      if(velocity.x < 0) velocity.x = 0;
    }
    if (position.x + size.x > gameRef.size.x) {
      position.x = gameRef.size.x - size.x;
      if(velocity.x > 0) velocity.x = 0;
    }

    if (invulnerable > 0) {
      invulnerable -= dt;
      if (invulnerable < 0) invulnerable = 0;
    }
  }

  void jump() {
    final groundY = gameRef.size.y - gameRef.groundHeight - gameRef.groundVisualOffset;
    if ((position.y + size.y) >= groundY - 0.5) {
      velocity.y = jumpSpeed;
    } else {
      // Si no está en el suelo, activar el buffer de salto
      _jumpBufferTimer = 0.15;
    }
  }
}
