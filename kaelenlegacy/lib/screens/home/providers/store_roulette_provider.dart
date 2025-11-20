// Provider y widget visual para la ruleta semicircular de la tienda
import 'dart:math';
import 'package:flutter/material.dart';

class StoreRouletteProvider {
  final List<String> items = [
    'Potion Cauldron',
    'Vampire Cap',
    'Fiery Joker',
    'Potion of Oblivion',
    'Crow Skull',
    'Witch Chest',
    'Mystic Broom',
  ];
  int selectedIndex = 0;
  void spinLeft() {
    selectedIndex = (selectedIndex - 1 + items.length) % items.length;
  }

  void spinRight() {
    selectedIndex = (selectedIndex + 1) % items.length;
  }

  String get selectedItem => items[selectedIndex];
}
