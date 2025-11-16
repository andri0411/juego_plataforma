import 'package:flutter/material.dart';

class MenuOption extends StatelessWidget {
  final String text;
  const MenuOption({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Spectral',
          fontStyle: FontStyle.italic,
          fontSize: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}
