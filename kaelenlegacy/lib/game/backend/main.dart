import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:kaelenlegacy/game/backend/runner_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/fondo.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: GameWidget(
        game: RunnerGame(),
        overlayBuilderMap: {
          'Controls': (context, game) {
            final RunnerGame g = game as RunnerGame;
            return SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: movement controls (aligned horizontally)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTapDown: (_) => g.moveLeftStart(),
                            onTapUp: (_) => g.moveStop(),
                            onTapCancel: () => g.moveStop(),
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.arrow_left, color: Colors.white),
                            ),
                          ),
                          GestureDetector(
                            onTapDown: (_) => g.moveRightStart(),
                            onTapUp: (_) => g.moveStop(),
                            onTapCancel: () => g.moveStop(),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.arrow_right, color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      // Right side: jump button
                      GestureDetector(
                        onTap: () => g.jump(),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 36),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          ,
          'GameOver': (context, game) {
            final RunnerGame g = game as RunnerGame;
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(color: Colors.black87.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Haz perdido', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // remove overlay then restart
                        g.overlays.remove('GameOver');
                        g.resetGame();
                      },
                      child: const Text('Reiniciar'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        initialActiveOverlays: const ['Controls'],
      ),
    ),
  );
}
