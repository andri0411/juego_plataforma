import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/providers/settings_config_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env if present and initialize Supabase if keys available
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('⚠️ .env load failed: $e');
  }

  // Supabase initialization disabled for local testing.
  debugPrint('⚠️ Supabase initialization skipped (local testing)');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsConfigProvider(),
      child: const MaterialApp(
        home: HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
