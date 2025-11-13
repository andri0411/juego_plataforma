import 'package:flutter/material.dart';

class HomeMenu extends StatelessWidget {
  final bool show;
  final VoidCallback onNewGame;
  final VoidCallback? onSettings;
  final VoidCallback onQuit;

  const HomeMenu({
    Key? key,
    required this.show,
    required this.onNewGame,
    this.onSettings,
    required this.onQuit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 12.0,
            left: 6.0,
            right: 12.0,
            bottom: 12.0,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 14.0,
                  ),
                  child: Text(
                    'Kaelen Legacy',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 3),
                          blurRadius: 8.0,
                          color: Colors.black87,
                        ),
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 4.0,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 34.0),

                // Menu options
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onNewGame,
                        child: Text(
                          'New Game',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6.0,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      GestureDetector(
                        onTap: onSettings ?? () {},
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6.0,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      GestureDetector(
                        onTap: onQuit,
                        child: Text(
                          'Quit game',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6.0,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
