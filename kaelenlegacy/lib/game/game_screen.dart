import 'dart:io' show exit;
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:kaelenlegacy/game/backend/runner_game.dart';

class GameScreen extends StatelessWidget {
  final int? startMap;
  const GameScreen({super.key, this.startMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: GameWidget(
          game: RunnerGame(startMap: startMap),
          overlayBuilderMap: {
            'Controls': (context, game) {
              final RunnerGame g = game as RunnerGame;
              return SafeArea(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                            GestureDetector(
                              onTapDown: (_) => g.jump(),
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
                    // Small menu icon at top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () async {
                          // Pause the game while the menu is open
                          g.pauseEngine();
                          final result = await showDialog<String>(
                            context: context,
                            barrierDismissible: true,
                            builder: (ctx) {
                                return AlertDialog(
                                  insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                                  title: const Text('Menú'),
                                  content: SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 320),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Removed "Reiniciar nivel" per request
                                          ListTile(
                                            title: const Text('Volver al inicio'),
                                            onTap: () {
                                              Navigator.of(ctx).pop('home');
                                            },
                                          ),
                                          ListTile(
                                            title: const Text('Salir del juego'),
                                            onTap: () {
                                              Navigator.of(ctx).pop('exit');
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop('cancel'),
                                      child: const Text('Cancelar'),
                                    ),
                                  ],
                                );
                              },
                          );

                          // Handle selection
                          if (result == 'restart') {
                            if (g.isSecondLevelActive) {
                              await g.restartSecondLevel();
                            } else {
                              g.resetGame();
                            }
                            g.resumeEngine();
                          } else if (result == 'home') {
                            // Pop the GameScreen to return to home and inform which doors are unlocked
                            final int unlocked = g.unlockedDoorsCount;
                            if (Navigator.of(context).canPop()) Navigator.of(context).pop('unlock:$unlocked');
                            // Do not resume game (screen is closing)
                          } else if (result == 'exit') {
                            // Close dialog first, then try to exit application
                            try {
                              SystemNavigator.pop();
                            } catch (e) {
                              exit(0);
                            }
                          } else {
                            // Cancelled/ dismissed -> resume
                            g.resumeEngine();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            // Game over overlay (shared with backend/main.dart)
            'GameOver': (context, game) {
              final RunnerGame g = game as RunnerGame;
              final bool lvl2 = g.isSecondLevelActive;
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(color: Colors.black87.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lvl2 ? 'Moriste' : 'Haz perdido', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          g.overlays.remove('GameOver');
                          // If we are in second level, restart only level 2; otherwise reset whole game
                          if (lvl2) {
                            g.restartSecondLevel();
                          } else {
                            g.resetGame();
                          }
                        },
                        child: Text(lvl2 ? 'Reintentar Nivel 2' : 'Reiniciar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            ,
            'ReturnHome': (context, game) {
              // Post-frame pop back to home with a specific result so
              // HomeScreen can jump to the final part of showmap.mp4.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop('activate_second_door');
                }
              });
              return const SizedBox.shrink();
            }
          },
          initialActiveOverlays: const ['Controls'],
        ),
      ),
    );
  }
}
