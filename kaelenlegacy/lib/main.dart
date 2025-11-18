import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home/home_screen.dart'; // Importa la pantalla principal actualizada

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:
          HomeScreen(), // Inicia con la pantalla principal que incluye la animación de carga
    );
  }
}
