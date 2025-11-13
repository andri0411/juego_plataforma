import 'package:flutter/material.dart';

class GameZoneScreen extends StatelessWidget {
  const GameZoneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/mapbackground.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
